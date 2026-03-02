import 'package:flutter/material.dart';
import '../../main.dart'; // عشان نستخدم navigatorKey

class DialogService {
  // متغير لمنع ظهور الرسائل فوق بعضها
  static bool _isDialogShowing = false;
  static DateTime? _lastAlertTime;

  static void showGlucoseAlert(double glucoseValue) {
    // نمنع التكرار (لو فات أقل من 5 دقايق على آخر تنبيه لا تظهر رسالة جديدة)
    if (_isDialogShowing) return;
    if (_lastAlertTime != null && DateTime.now().difference(_lastAlertTime!).inMinutes < 5) return;

    if (glucoseValue > 180) {
      _showDialog(
        title: "Hyperglycemia Alert!",
        color: Colors.red.shade800,
        glucose: glucoseValue,
        icon: Icons.show_chart,
        instructions: [
          "Drink plenty of water to help flush excess sugar.",
          "Engage in light physical activity like a 15-minute walk.",
          "Avoid consuming carbohydrate-rich foods or sugary drinks for now."
        ],
        note: "Note: These are general guidelines. If high sugar persists, consult your doctor.",
      );
    } else if (glucoseValue < 70 && glucoseValue > 0) {
      _showDialog(
        title: "Hypoglycemia Alert!",
        color: Colors.deepOrange,
        glucose: glucoseValue,
        icon: Icons.trending_down,
        instructions: [
          "Take 15 grams of fast-acting carbs (e.g., 1/2 cup of juice).",
          "Eat 3-4 glucose tablets.",
          "Take 1 tablespoon of sugar or honey.",
          "Then wait 15 minutes and recheck your blood sugar."
        ],
        note: "",
      );
    }
  }

  static void _showDialog({
    required String title,
    required Color color,
    required double glucose,
    required IconData icon,
    required List<String> instructions,
    required String note,
  }) {
    _isDialogShowing = true;
    _lastAlertTime = DateTime.now();

    final context = navigatorKey.currentContext!;

    showDialog(
      context: context,
      barrierDismissible: false, // يمنع اغلاق الرسالة بالضغط خارجها
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Current Glucose: ${glucose.toInt()} mg/dL",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 15),
              if (title.contains("Hypo"))
                const Text("Take 15 grams of fast-acting carbs, such as:", style: TextStyle(fontWeight: FontWeight.bold)),
              if (title.contains("Hyper"))
                const Text("Recommended Actions:", style: TextStyle(fontWeight: FontWeight.bold)),
              
              const SizedBox(height: 10),
              ...instructions.map((text) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline, size: 18, color: color),
                    const SizedBox(width: 8),
                    Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
                  ],
                ),
              )),
              
              if (note.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(note, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
              ]
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                _isDialogShowing = false;
                Navigator.of(context).pop();
              },
              child: const Text("OK", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    ).then((_) => _isDialogShowing = false);
  }
}

class navigatorKey {
  static get currentContext => null;
}