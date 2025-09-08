import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailOtpService {
  // ✅ Use your actual deployed Firebase Function URLs
  final String _sendOtpUrl =
      "https://us-central1-calligro-bcfb2.cloudfunctions.net/sendEmailOtp";
  final String _verifyOtpUrl =
      "https://us-central1-calligro-bcfb2.cloudfunctions.net/verifyEmailOtp";

  /// Send OTP to the given email
  Future<bool> sendOtp(String email) async {
    try {
      final response = await http.post(
        Uri.parse(_sendOtpUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data["error"] ?? "Failed to send OTP");
      }
    } catch (e) {
      throw Exception("Network error while sending OTP: $e");
    }
  }

  /// Verify OTP
  Future<bool> verifyOtp(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse(_verifyOtpUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "otp": otp}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["valid"] == true;
      } else {
        return false;
      }
    } catch (e) {
      throw Exception("Network error while verifying OTP: $e");
    }
  }
}
