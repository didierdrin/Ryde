import 'dart:convert';

import 'package:http/http.dart';
import 'package:ryde_rw/service/user_service.dart';

class WhatsAppService {
  static const String url =
      'https://graph.facebook.com/v19.0/396791596844039/messages';
  static Future<bool> sendOTP(String number, String code) async {
    try {
      final token = await UserService.getToken();
      final client = Client();
      await client.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'messaging_product': 'whatsapp',
          'recipient_type': 'individual',
          'to': number,
          'type': 'template',
          'template': {
            'name': 'ikanisa',
            'language': {'code': 'en'},
            'components': [
              {
                'type': 'body',
                'parameters': [
                  {'type': 'text', 'text': code},
                ],
              },
              {
                'type': 'button',
                'sub_type': 'url',
                'index': '0',
                'parameters': [
                  {'type': 'text', 'text': code},
                ],
              },
            ],
          },
        }),
      );
      return true;
    } catch (e) {
      if (number == '+250783655972') {
        return false;
      }
      throw Exception('fail to send');
    }
  }
}
