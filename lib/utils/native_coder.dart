import 'package:flutter/services.dart';

class PlatformChannelService { // com.ikanisa.lifuti
  static const platform = MethodChannel('com.example.ryde_rw/platform_channel');

  Future<String> invokeNativeFunction() async {
    try {
      final String result = await platform.invokeMethod('getNativeData');
      return result;
    } on PlatformException catch (e) {
      return "Failed to get native data: '${e.message}'.";
    }
  }
}

