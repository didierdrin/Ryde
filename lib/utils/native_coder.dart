import 'package:flutter/services.dart';

class PlatformChannelService {
  static const platform = MethodChannel('com.ikanisa.lifuti/platform_channel');

  Future<String> invokeNativeFunction() async {
    try {
      final String result = await platform.invokeMethod('getNativeData');
      return result;
    } on PlatformException catch (e) {
      return "Failed to get native data: '${e.message}'.";
    }
  }
}

