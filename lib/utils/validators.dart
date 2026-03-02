class Validators {
  static String? required(String? v, {String msg = "Required"}) {
    if (v == null || v.trim().isEmpty) return msg;
    return null;
  }

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return "Email is required";
    final x = v.trim();
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(x);
    if (!ok) return "Invalid email";
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return "Password is required";
    if (v.length < 8) return "Min 8 characters";
    final hasUpper = RegExp(r'[A-Z]').hasMatch(v);
    final hasLower = RegExp(r'[a-z]').hasMatch(v);
    final hasNum = RegExp(r'\d').hasMatch(v);
    if (!(hasUpper && hasLower && hasNum)) {
      return "Use upper, lower, number";
    }
    return null;
  }

  static String? phoneEG(String? v) {
    if (v == null || v.trim().isEmpty) return "Phone is required";
    final x = v.trim().replaceAll(" ", "");
    // مصري بسيط: 01xxxxxxxxx (11 رقم)
    final ok = RegExp(r'^01\d{9}$').hasMatch(x);
    if (!ok) return "Invalid phone (EG: 01xxxxxxxxx)";
    return null;
  }

  static String? numberRange(String? v, {required int min, required int max, String? label}) {
    if (v == null || v.trim().isEmpty) return "${label ?? "Value"} is required";
    final n = int.tryParse(v.trim());
    if (n == null) return "Enter a valid number";
    if (n < min || n > max) return "${label ?? "Value"} must be $min-$max";
    return null;
  }
}
