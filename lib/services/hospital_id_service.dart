import 'dart:math';

class HospitalIdService {
  static String generateHospitalId(String hospitalName) {
    final clean = hospitalName
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();

    final prefix = clean.isEmpty
        ? 'HSP'
        : clean.substring(0, clean.length >= 4 ? 4 : clean.length);

    final rnd = Random();
    final number = 100000 + rnd.nextInt(900000);

    return '$prefix-$number';
  }
}