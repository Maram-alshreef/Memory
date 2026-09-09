import 'dart:convert';

import 'package:http/http.dart' as http;

class OtpService {
  OtpService({this.baseUrl = 'http://127.0.0.1:3000'});

  final String baseUrl;

  Future<String?> requestCode(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/otp/request'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim().toLowerCase()}),
    );

    final data = _decode(response);
    if (response.statusCode >= 200 && response.statusCode < 300 && data['ok'] == true) {
      return null;
    }

    return data['message']?.toString() ?? 'تعذر إرسال رمز التحقق';
  }

  Future<String?> verifyCode(String email, String code) async {
    final response = await http.post(
      Uri.parse('$baseUrl/otp/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'code': code.trim(),
      }),
    );

    final data = _decode(response);
    if (response.statusCode >= 200 && response.statusCode < 300 && data['ok'] == true) {
      return null;
    }

    return data['message']?.toString() ?? 'رمز التحقق غير صحيح';
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      // استخدم الرسالة العامة إذا كانت استجابة الخادم غير صالحة.
    }
    return <String, dynamic>{};
  }
}
