import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vital_sample.dart';
import '../models/alert_item.dart';
import '../services/thresholds.dart';
import '../services/notification_service.dart';

class VitalsInsightsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // تحليل القراءة وإصدار تنبيهات ذكية
  Future<void> analyzeAndAlert(VitalSample sample) async {
    final now = DateTime.now();
    
    // 1. تحليل السكر (Glucose) - المنطق الذكي المتقدم
    if (sample.glucose > 0) {
      await _analyzeGlucose(sample, now);
    }

    // 2. تحليل القلب (Heart Rate)
    if (sample.hr > Thresholds.hrHigh) {
      await _createAndSaveAlert(
        sample.patientId, 
        'High Heart Rate', 
        'HR is ${sample.hr} bpm. Please rest immediately.', 
        'high', 
        now
      );
    } else if (sample.hr < Thresholds.hrLow && sample.hr > 0) {
      await _createAndSaveAlert(
        sample.patientId, 
        'Low Heart Rate', 
        'HR is ${sample.hr} bpm. If you feel dizzy, call for help.', 
        'high', 
        now
      );
    }

    // 3. تحليل الأكسجين (SpO2)
    if (sample.spo2 < Thresholds.spo2Low && sample.spo2 > 0) {
      await _createAndSaveAlert(
        sample.patientId, 
        'Low Oxygen', 
        'Oxygen is ${sample.spo2}%. Deep breath and sit straight.', 
        'critical', 
        now
      );
    }

    // 4. السقوط (Fall Detection)
    if (sample.fallFlag) {
      await _createAndSaveAlert(
        sample.patientId, 
        'SOS', // نوع SOS عشان يظهر باللون الأحمر
        'Fall Detected! Automated SOS triggered.', 
        'critical', 
        now
      );
      // إشعار صوتي فوري
      NotificationService.instance.show('FALL DETECTED!', 'Sending emergency alert...');
    }
  }

  // --- منطق السكر التفصيلي ---
  Future<void> _analyzeGlucose(VitalSample sample, DateTime now) async {
    final g = sample.glucose;

    if (g > 250) {
      // --- حالة خطر قصوى (غيبوبة سكر محتملة) ---
      await _createAndSaveAlert(
        sample.patientId,
        'SOS', // تفعيل SOS تلقائي
        'CRITICAL HIGH GLUCOSE ($g). Risk of Ketoacidosis. Help needed!',
        'critical',
        now
      );
      NotificationService.instance.show('EMERGENCY', 'Glucose Critical! SOS Sent.');
    } 
    else if (g > 180) {
      // --- عالي متوسط (توجيه نصائح) ---
      await _createAndSaveAlert(
        sample.patientId,
        'High Glucose Alert',
        'Glucose is $g mg/dL.\n1. Drink plenty of water.\n2. Avoid carbs/sugar now.\n3. Take insulin if prescribed.',
        'medium',
        now
      );
    } 
    else if (g < 70) {
      // --- واطي (خطر هبوط) ---
      await _createAndSaveAlert(
        sample.patientId,
        'Hypoglycemia Alert',
        'Glucose is low ($g mg/dL)!\n1. Eat 15g fast sugar (juice/candy).\n2. Recheck in 15 mins.\n3. Do not drive.',
        'high',
        now
      );
    }
  }

  // دالة مساعدة لحفظ التنبيه في Firestore فوراً
  Future<void> _createAndSaveAlert(String pid, String type, String msg, String severity, DateTime time) async {
    final alert = AlertItem(
      id: '', 
      patientId: pid,
      type: type,
      message: msg,
      severity: severity,
      timestamp: time,
    );

    // الحفظ في قاعدة البيانات (عشان يظهر في History)
    await _db.collection('alerts').add(alert.toJson());
    
    // إرسال إشعار للموبايل
    if (severity == 'high' || severity == 'critical') {
       NotificationService.instance.show(type, msg);
    }
  }
}