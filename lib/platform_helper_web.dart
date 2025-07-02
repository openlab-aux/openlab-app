import 'package:flutter/material.dart';
import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;
import 'platform_helper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class WebPlatformHelper implements PlatformHelper {
  @override
  http.Client createHttpClient() {
    return BrowserClient();
  }

  @override
  bool isMobile() {
    return !kIsWeb;
  }

  @override
  bool isIOS() {
    return false;
  }

  @override
  PlatformHelper dummrumleuchte() =>
      throw UnsupportedError('Unsupported platform');
  @override
  Future<List<ActiveHost>> scanLocalNetwork(BuildContext context) =>
      throw UnsupportedError('Unsupported platform');

  @override
  void configureNetworkTools() =>
      throw UnsupportedError('Unsupported platform');
}

PlatformHelper createPlatformHelper() => WebPlatformHelper();
