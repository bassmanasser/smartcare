const functions = require('firebase-functions');
const admin = require('firebase-admin');
const OpenAI = require('openai'); // هنحتاجه للـ AI bot برضه

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

// =============== SMART ALERTS ON NEW VITAL ===============

exports.onVitalCreated = functions.firestore
  .document('vitals/{vitalId}')
  .onCreate(async (snap, context) => {
    const v = snap.data();
    const patientId = v.patientId;
    const hr = Number(v.hr || 0);
    const spo2 = Number(v.spo2 || 0);
    const tempC = v.temp_c != null ? Number(v.temp_c) : null;
    const glucose = v.glucose_mgdl != null ? Number(v.glucose_mgdl) : null;

    const alerts = [];
    const now = Date.now();

    // HR  (normal adult ~60–100 bpm) :contentReference[oaicite:0]{index=0}
    if (hr > 110) {
      alerts.push({
        patientId,
        type: 'tachycardia',
        message: `High heart rate detected (${hr} bpm).`,
        severity: 'high',
        t: now,
      });
    } else if (hr < 50 && hr > 0) {
      alerts.push({
        patientId,
        type: 'bradycardia',
        message: `Low heart rate detected (${hr} bpm).`,
        severity: 'medium',
        t: now,
      });
    }

    // SpO2  (normal 95–100%, <90% low) :contentReference[oaicite:1]{index=1}
    if (spo2 > 0) {
      if (spo2 < 90) {
        alerts.push({
          patientId,
          type: 'severe_hypoxemia',
          message: `Critical low oxygen level (${spo2}%).`,
          severity: 'high',
          t: now,
        });
      } else if (spo2 < 94) {
        alerts.push({
          patientId,
          type: 'low_spo2',
          message: `Low oxygen level (${spo2}%).`,
          severity: 'medium',
          t: now,
        });
      }
    }

    // Temperature  (fever ≥38 °C) :contentReference[oaicite:2]{index=2}
    if (tempC != null) {
      if (tempC >= 39.0) {
        alerts.push({
          patientId,
          type: 'high_fever',
          message: `High fever detected (${tempC.toFixed(1)} °C).`,
          severity: 'high',
          t: now,
        });
      } else if (tempC >= 38.0) {
        alerts.push({
          patientId,
          type: 'fever',
          message: `Fever detected (${tempC.toFixed(1)} °C).`,
          severity: 'medium',
          t: now,
        });
      }
    }

    // Glucose (values تقريبية educational مش تشخيص) :contentReference[oaicite:3]{index=3}
    if (glucose != null) {
      if (glucose < 70) {
        alerts.push({
          patientId,
          type: 'hypoglycemia',
          message: `Low blood glucose (${glucose} mg/dL).`,
          severity: 'high',
          t: now,
        });
      } else if (glucose > 250) {
        alerts.push({
          patientId,
          type: 'severe_hyperglycemia',
          message: `Very high blood glucose (${glucose} mg/dL).`,
          severity: 'high',
          t: now,
        });
      } else if (glucose > 180) {
        alerts.push({
          patientId,
          type: 'hyperglycemia',
          message: `High blood glucose (${glucose} mg/dL).`,
          severity: 'medium',
          t: now,
        });
      }
    }

    if (!alerts.length) return null;

    const batch = db.batch();
    alerts.forEach((a) => {
      const ref = db.collection('alerts').doc();
      batch.set(ref, {
        ...a,
        id: ref.id,
      });
    });

    await batch.commit();
    return null;
  });
  // =============== AI CHAT BOT (HTTP ENDPOINT) ===============

// لازم تحطي OPENAI_API_KEY في environment:
// firebase functions:config:set openai.key="YOUR_API_KEY"
// وبعدين في الكود نقرأها:
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY || functions.config().openai.key,
});

exports.aiChat = functions.https.onRequest(async (req, res) => {
  // CORS بسيط
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  try {
    const body = req.body || {};
    const userMessage = (body.message || '').toString();
    const patientId = (body.patientId || '').toString();
    const vitalsSummary = (body.vitalsSummary || '').toString();

    if (!userMessage) {
      res.status(400).json({ error: 'message is required' });
      return;
    }

    // system prompt آمن: معلومات عامة فقط، مفيش تشخيص أو وصف دواء
    const systemPrompt = `
You are SmartCare, a helpful health information assistant for a telemedicine app.

- You only provide **general educational information** about symptoms, lifestyle, and how to talk to a doctor.
- You **must not** give a diagnosis, decide treatments, or change medications.
- For any serious symptoms, red-flag vitals, or emergencies, always say clearly:
  "This could be serious. Please contact your doctor or local emergency services immediately."
- The user may have chronic conditions (e.g. diabetes, heart disease). Encourage regular follow-up with their clinician.
- If you are unsure, say you are not sure and suggest speaking with their healthcare provider.

Here is a short summary of their recent vitals (may be empty):
${vitalsSummary}
    `.trim();

    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini', // غيّري الموديل لو حابة
      messages: [
        { role: 'system', content: systemPrompt },
        {
          role: 'user',
          content: userMessage,
        },
      ],
      max_tokens: 400,
      temperature: 0.4,
    });

    const reply =
      completion.choices?.[0]?.message?.content?.toString() ||
      "I'm sorry, I couldn't generate a response.";

    res.json({
      reply,
      patientId,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({
      error: 'AI error',
    });
  }
});

