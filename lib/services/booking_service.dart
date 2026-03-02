import 'package:cloud_firestore/cloud_firestore.dart';

class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // وظيفة لحفظ الحجز في قاعدة البيانات
  Future<void> createBooking({
    required String patientId,
    required String doctorId,
    required DateTime date,
    required String timeSlot,
  }) async {
    try {
      await _db.collection('bookings').add({
        'patientId': patientId,
        'doctorId': doctorId,
        'bookingDate': date.toIso8601String(),
        'timeSlot': timeSlot,
        'status': 'pending', // حالة الحجز (منتظر، مقبول، مرفوض)
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error creating booking: $e");
      rethrow;
    }
  }
}