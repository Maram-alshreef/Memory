import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class OtpService {
  OtpService({String? baseUrl})
      : baseUrl = (baseUrl ?? _publicServerUrl).replaceFirst(RegExp(r'/$'), '');

  // بعد رفع otp_server، استبدل هذا الرابط برابط HTTPS الذي ستعطيك إياه خدمة الاستضافة.
  // مثال: https://memora-otp.onrender.com
  static const String _publicServerUrl =
      'https://memora-otp-server-production.up.railway.app';

  final String baseUrl;

  Future<String?> requestCode(String email) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/otp/request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim().toLowerCase()}),
      )
          .timeout(const Duration(seconds: 20));

      final data = _decode(response);
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          data['ok'] == true) {
        return null;
      }

      return data['message']?.toString() ?? 'تعذر إرسال رمز التحقق';
    } on TimeoutException {
      return 'انتهت مهلة الاتصال بالخادم، حاول مرة أخرى';
    } on http.ClientException {
      return 'تعذر الاتصال بخادم التحقق';
    } catch (_) {
      return 'حدث خطأ أثناء إرسال رمز التحقق';
    }
  }

  Future<String?> verifyCode(String email, String code) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/otp/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'code': code.trim(),
        }),
      )
          .timeout(const Duration(seconds: 20));

      final data = _decode(response);
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          data['ok'] == true) {
        return null;
      }

      return data['message']?.toString() ?? 'رمز التحقق غير صحيح';
    } on TimeoutException {
      return 'انتهت مهلة الاتصال بالخادم، حاول مرة أخرى';
    } on http.ClientException {
      return 'تعذر الاتصال بخادم التحقق';
    } catch (_) {
      return 'حدث خطأ أثناء التحقق من الرمز';
    }
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
