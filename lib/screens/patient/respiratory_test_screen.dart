import 'package:flutter/material.dart';
import '../../services/audio_predictor.dart';
import '../../utils/constants.dart'; // لاستخدام ألوان التطبيق

class RespiratoryTestScreen extends StatefulWidget {
  const RespiratoryTestScreen({super.key});

  @override
  State<RespiratoryTestScreen> createState() => _RespiratoryTestScreenState();
}

class _RespiratoryTestScreenState extends State<RespiratoryTestScreen> {
  final AudioPredictor predictor = AudioPredictor();

  bool isLoading = false;
  String status = 'Press Start to record (20s)';
  Map<String, dynamic>? result;

  Future<void> onStart() async {
    setState(() {
      isLoading = true;
      result = null;
      status = 'Recording... Please breathe normally near the mic.';
    });

    try {
      final res = await predictor.recordThenPredict();
      setState(() {
        result = res;
        status = 'Analysis Complete ✅';
      });
    } catch (e) {
      setState(() {
        status = 'Error: $e';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    predictor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = result?['label'];
    final conf = result?['confidence'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Respiratory Check'),
        backgroundColor: PETROL_DARK,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Icon(
                isLoading ? Icons.mic : Icons.multitrack_audio,
                size: 80,
                color: isLoading ? Colors.redAccent : PETROL,
              ),
              const SizedBox(height: 20),
              
              // Status Text
              Text(
                status,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),

              // Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : onStart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PETROL,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Icon(Icons.play_arrow),
                  label: Text(isLoading ? 'Recording & Analyzing...' : 'Start Test'),
                ),
              ),

              const SizedBox(height: 40),

              // Results Area
              if (result != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Column(
                    children: [
                      const Text("Prediction Result", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                      const Divider(),
                      Text(
                        '$label', 
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 5),
                      Text('Confidence: ${(conf * 100).toStringAsFixed(1)}%'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}