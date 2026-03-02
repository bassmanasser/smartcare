import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class AudioPredictor {
  final AudioRecorder _recorder = AudioRecorder();

  static const String baseUrl = 'https://resp-api-production.up.railway.app';
  static const int recordSeconds = 20;

  Future<bool> _ensureMicPermission() async {
    return await _recorder.hasPermission();
  }

  Future<String> _buildFilePath() async {
    final dir = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    return '${dir.path}/resp_$ts.m4a';
  }

  /// Record 20 seconds and return file path
  Future<String> record20Seconds() async {
    final ok = await _ensureMicPermission();
    if (!ok) {
      throw Exception('Microphone permission denied');
    }

    final path = await _buildFilePath();

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );

    await Future.delayed(const Duration(seconds: recordSeconds));

    final recordedPath = await _recorder.stop();
    if (recordedPath == null) {
      throw Exception('Recording failed (no path)');
    }
    return recordedPath;
  }

  /// Upload audio file to API and return JSON
  Future<Map<String, dynamic>> predictFromFile(String audioPath) async {
    final uri = Uri.parse('$baseUrl/predict_audio');
    final request = http.MultipartRequest('POST', uri);

    request.files.add(await http.MultipartFile.fromPath('file', audioPath));

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode == 200) {
      return jsonDecode(body) as Map<String, dynamic>;
    } else {
      throw Exception('API error ${streamed.statusCode}: $body');
    }
  }

  /// Full pipeline: record then predict
  Future<Map<String, dynamic>> recordThenPredict() async {
    final path = await record20Seconds();
    try {
      final result = await predictFromFile(path);
      return result;
    } finally {
      try {
        final f = File(path);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
