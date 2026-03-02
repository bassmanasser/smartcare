import 'dart:io';
// import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  static Future<String> uploadDoctorDocImage(File file, String uid) async {
    // Temporary mock implementation until firebase_storage is added to pubspec.yaml
    // final ref = FirebaseStorage.instance
    //     .ref()
    //     .child("doctor_docs")
    //     .child("$uid-${DateTime.now().millisecondsSinceEpoch}.jpg");
    // await ref.putFile(file);
    // return await ref.getDownloadURL();
    return "https://placeholder.com/doctor_doc.jpg";
  }
}