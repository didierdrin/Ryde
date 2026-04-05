import 'package:http/http.dart';

/// Web / non-IO platforms: default [Client].
Client createPlatformHttpClient() => Client();
