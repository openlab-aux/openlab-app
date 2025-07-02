import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'platform_helper_stub.dart'
    if (dart.library.io) 'platform_helper_io.dart'
    if (dart.library.html) 'platform_helper_web.dart';

abstract class PlatformHelper {
  http.Client createHttpClient();
  bool isMobile();
  void dummrumleuchte();
  Future<List<ActiveHost>> scanLocalNetwork(BuildContext context);
  bool isIOS();

  void configureNetworkTools();
}

PlatformHelper getPlatformHelper() => createPlatformHelper();

class ActiveHost {
  String address;
  String? macAddress;

  ActiveHost(this.address, this.macAddress);
}
