import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/telemetry_model.dart';

class GeminiService {
  final String apiKey;

  GeminiService(this.apiKey);

  Future<String> getAdvice(TelemetryData stats) async {
    if (apiKey.isEmpty) return 'AI Core offline. Gemini API key not configured.';
    try {
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{
            'parts': [{'text': _buildPrompt(stats)}]
          }],
          'generationConfig': {'temperature': 0.4, 'maxOutputTokens': 150}
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? 'AI analysis unavailable.';
      }
      return 'AI Core: Unable to reach inference endpoint.';
    } catch (e) {
      return 'AI Core: Connection error. Retrying...';
    }
  }

  String _buildPrompt(TelemetryData stats) {
    return "You are a real-time Android gaming performance advisor. "
        "Analyze these hardware telemetry readings and give ONE short, actionable sentence of optimization advice:\n"
        "- CPU: ${stats.cpuUsage.toStringAsFixed(1)}% at ${stats.cpuFreq.toStringAsFixed(2)} GHz (${stats.cpuTemp.toStringAsFixed(0)}°C)\n"
        "- GPU: ${stats.gpuUsage.toStringAsFixed(1)}% at ${stats.gpuFreq.toStringAsFixed(2)} GHz (${stats.gpuTemp.toStringAsFixed(0)}°C)\n"
        "- FPS: ${stats.fps}\n"
        "- RAM: ${stats.ramUsage.toStringAsFixed(1)} GB used\n"
        "- Battery: ${stats.batteryLevel.toStringAsFixed(0)}% at ${stats.batteryTemp.toStringAsFixed(0)}°C\n"
        "- Thermal Status: ${stats.throttleStatus}\n"
        "- Ping: ${stats.ping.toStringAsFixed(0)}ms\n\n"
        "Respond as a cyberpunk AI with gaming focus. Keep it under 20 words.";
  }
}
