// lib/services/analysis_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/analysis_result.dart';

class AnalysisService {
  static const String _baseUrl = 'http://localhost:8000';

  static Future<AnalysisResult> analyzeCode(String code, String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/analyze'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'code': code}),
    );

    if (response.statusCode == 200) {
      return AnalysisResult.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Ошибка: ${response.statusCode}\n${response.body}');
    }
  }
}
