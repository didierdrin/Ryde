import 'dart:io' show HttpClient, Platform;

import 'package:cronet_http/cronet_http.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';

/// Android: Cronet avoids flaky DNS with Dart's socket stack. Other IO: [IOClient].
Client createPlatformHttpClient() {
  if (Platform.isAndroid) {
    final engine = CronetEngine.build(
      cacheMode: CacheMode.memory,
      userAgent: 'RydeMobile/1.0',
    );
    return CronetClient.fromCronetEngine(engine, closeEngine: true);
  }
  return IOClient(HttpClient()..userAgent = 'RydeMobile/1.0');
}
