import 'package:flutter/material.dart';
import '../utils/constants.dart'; // Make sure constants.dart is in lib/utils/

enum GlucoseState { low, high }

class GlucoseRecommendationDialog extends StatelessWidget {
  final GlucoseState state;
  final int glucoseLevel;

  const GlucoseRecommendationDialog({
    super.key,
    required this.state,
    required this.glucoseLevel,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLow = state == GlucoseState.low;

    final title = isLow ? "Hypoglycemia Alert! 📉" : "Hyperglycemia Alert! 📈";
    final subtitle = "Current Glucose: $glucoseLevel mg/dL";
    final recommendations = isLow ? _getLowSugarRecommendations() : _getHighSugarRecommendations();
    final adviceText = isLow
        ? "Then wait 15 minutes and recheck your blood sugar."
        : "Note: These are general guidelines. If high sugar persists, consult your doctor.";

    return AlertDialog(
      title: Text(title, style: TextStyle(color: isLow ? Colors.orange.shade800 : Colors.red.shade700, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ...recommendations,
            const SizedBox(height: 16),
            Text(
              adviceText,
              style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("OK"),
        )
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
    );
  }

  List<Widget> _getLowSugarRecommendations() {
    return [
      const Text(
        "Take 15 grams of fast-acting carbs, such as:",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      _buildRecommendationItem(Icons.local_drink, "1/2 cup (120ml) of juice or regular soda."),
      _buildRecommendationItem(Icons.set_meal, "3-4 glucose tablets."), // Using a different icon
      _buildRecommendationItem(Icons.water_drop, "1 tablespoon (15ml) of sugar or honey."),
    ];
  }

  List<Widget> _getHighSugarRecommendations() {
    return [
      const Text(
        "Recommended Actions:",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      _buildRecommendationItem(Icons.water_drop_outlined, "Drink plenty of water to help flush excess sugar."),
      _buildRecommendationItem(Icons.directions_walk, "Engage in light physical activity like a 15-minute walk (if advised by your doctor)."),
      _buildRecommendationItem(Icons.no_food_outlined, "Avoid consuming carbohydrate-rich foods or sugary drinks for now."),
    ];
  }

  Widget _buildRecommendationItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: PETROL, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}