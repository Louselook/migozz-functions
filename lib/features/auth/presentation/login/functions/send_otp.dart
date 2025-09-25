import 'package:migozz_app/email_otp_custom.dart';

Future<Map<String, dynamic>> sendOTP({
  required String email,
  String? myOTP,
}) async {
  bool sent = await EmailOTP.sendOTP(email: email);
  if (sent) {
    myOTP = EmailOTP.getOTP();
  }
  return {"sent": sent, "myOTP": myOTP};
}
