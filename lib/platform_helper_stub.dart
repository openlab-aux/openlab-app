import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'platform_helper.dart';

PlatformHelper createPlatformHelper() =>
    throw UnsupportedError('Unsupported platform');

PlatformHelper isMobile() => throw UnsupportedError('Unsupported platform');
bool isIOS() => throw UnsupportedError('Unsupported platform');
PlatformHelper domainLookup(String host) =>
    throw UnsupportedError('Unsupported platform');
Future<List<ActiveHost>> scanLocalNetwork(BuildContext context) =>
    throw UnsupportedError('Unsupported platform');

void configureNetworkTools() => throw UnsupportedError('Unsupported platform');
