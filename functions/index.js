const functions = require('firebase-functions');
const admin = require('firebase-admin');
const OpenAI = require('openai');

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY || functions.config().openai?.key,
});

function normalizeNumber(value) {
  const n = Number(value);
  return Number.isFinite(n) ? n : 0;
}

async function getPatientInstitutionId(patientId) {
  if (!patientId) return '';
  const patientSnap = await db.collection('users').doc(patientId).get();
  if (!patientSnap.exists) return '';
  return (patientSnap.data()?.institutionId || '').toString();
}

async function createAlert({
  patientId,
  institutionId,
  type,
  message,
  severity,
  timestamp,
  sourceVitalId,
}) {
  const payload = {
    patientId,
    institutionId,
    type,
    message,
    severity,
    timestamp: admin.firestore.Timestamp.fromDate(timestamp),
    sourceVitalId: sourceVitalId || '',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  const batch = db.batch();

  const patientAlertRef = db
    .collection('users')
    .doc(patientId)
    .collection('alerts')
    .doc();

  batch.set(patientAlertRef, {
    ...payload,
    id: patientAlertRef.id,
  });

  const globalAlertRef = db.collection('alerts').doc();
  batch.set(globalAlertRef, {
    ...payload,
    id: globalAlertRef.id,
  });

  await batch.commit();
}

exports.onVitalCreated = functions.firestore
  .document('users/{userId}/vitals/{vitalId}')
  .onCreate(async (snap, context) => {
    const vital = snap.data() || {};
    const patientId = context.params.userId;
    const vitalId = context.params.vitalId;
    const institutionId = await getPatientInstitutionId(patientId);

    const hr = normalizeNumber(vital.hr);
    const spo2 = normalizeNumber(vital.spo2);
    const tempC = vital.temperature != null
      ? normalizeNumber(vital.temperature)
      : normalizeNumber(vital.temp_c);
    const glucose = vital.glucose != null
      ? normalizeNumber(vital.glucose)
      : normalizeNumber(vital.glucose_mgdl);
    const fallFlag = vital.fallFlag === true || vital.fall_flag === true;

    const now = new Date();
    const alerts = [];

    if (hr > 110) {
      alerts.push({
        type: 'tachycardia',
        message: `High heart rate detected (${hr} bpm).`,
        severity: 'high',
      });
    } else if (hr > 0 && hr < 50) {
      alerts.push({
        type: 'bradycardia',
        message: `Low heart rate detected (${hr} bpm).`,
        severity: 'medium',
      });
    }

    if (spo2 > 0) {
      if (spo2 < 90) {
        alerts.push({
          type: 'severe_hypoxemia',
          message: `Critical low oxygen level (${spo2}%).`,
          severity: 'critical',
        });
      } else if (spo2 < 94) {
        alerts.push({
          type: 'low_spo2',
          message: `Low oxygen level (${spo2}%).`,
          severity: 'medium',
        });
      }
    }

    if (tempC > 0) {
      if (tempC >= 39.0) {
        alerts.push({
          type: 'high_fever',
          message: `High fever detected (${tempC.toFixed(1)} °C).`,
          severity: 'high',
        });
      } else if (tempC >= 38.0) {
        alerts.push({
          type: 'fever',
          message: `Fever detected (${tempC.toFixed(1)} °C).`,
          severity: 'medium',
        });
      }
    }

    if (glucose > 0) {
      if (glucose < 70) {
        alerts.push({
          type: 'hypoglycemia',
          message: `Low blood glucose (${glucose} mg/dL).`,
          severity: 'high',
        });
      } else if (glucose > 250) {
        alerts.push({
          type: 'severe_hyperglycemia',
          message: `Very high blood glucose (${glucose} mg/dL).`,
          severity: 'critical',
        });
      } else if (glucose > 180) {
        alerts.push({
          type: 'hyperglycemia',
          message: `High blood glucose (${glucose} mg/dL).`,
          severity: 'medium',
        });
      }
    }

    if (fallFlag) {
      alerts.push({
        type: 'fall_detected',
        message: 'Fall detected. Emergency follow-up may be needed.',
        severity: 'critical',
      });
    }

    if (!alerts.length) {
      return null;
    }

    for (const alert of alerts) {
      await createAlert({
        patientId,
        institutionId,
        type: alert.type,
        message: alert.message,
        severity: alert.severity,
        timestamp: now,
        sourceVitalId: vitalId,
      });
    }

    return null;
  });

exports.aiChat = functions.https.onRequest(async (req, res) => {
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
    if (!openai.apiKey) {
      res.status(500).json({ error: 'Missing OPENAI_API_KEY' });
      return;
    }

    const body = req.body || {};
    const userMessage = (body.message || '').toString().trim();
    const patientId = (body.patientId || '').toString().trim();
    const patientName = (body.patientName || '').toString().trim();
    const languageCode = (body.languageCode || 'en').toString().trim();
    const vitalsSummary = (body.vitalsSummary || '').toString().trim();

    if (!userMessage) {
      res.status(400).json({ error: 'message is required' });
      return;
    }

    const systemPrompt = `
You are SmartCare, a helpful health-information assistant inside a medical monitoring app.

Rules:
- Provide only general educational guidance.
- Do not diagnose.
- Do not prescribe or change medications.
- If the user mentions severe symptoms or dangerous readings, clearly tell them to contact their doctor or emergency services immediately.
- Keep answers short, calm, and practical.
- Reply in ${languageCode === 'ar' ? 'Arabic' : 'English'}.

Patient name: ${patientName || 'Unknown'}
Patient id: ${patientId || 'Unknown'}

Recent vitals summary:
${vitalsSummary || 'No recent vitals available.'}
`.trim();

    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      temperature: 0.4,
      max_tokens: 400,
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userMessage },
      ],
    });

    const reply =
      completion.choices?.[0]?.message?.content?.toString() ||
      "I'm sorry, I couldn't generate a response.";

    res.status(200).json({ reply });
  } catch (err) {
    console.error('aiChat error:', err);
    res.status(500).json({ error: 'AI error' });
  }
});
