import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io' show HttpClient, InternetAddress, Platform, X509Certificate;
import 'package:http/io_client.dart';
import 'package:openlabflutter/platform_helper.dart';
import 'package:path_provider/path_provider.dart';

import 'dart:developer' as developer; // Import for logging
import 'package:udp/udp.dart';
import 'package:network_tools/network_tools.dart'
    hide ActiveHost; // Retained for network scanning
import 'package:network_tools_flutter/network_tools_flutter.dart'
    hide ActiveHost;
import 'package:dart_ping/dart_ping.dart'; // Retained for pinging

class MobilePlatformHelper implements PlatformHelper {
  @override
  http.Client createHttpClient() {
    final httpClient = HttpClient();
    // Disable certificate verification
    httpClient.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
          return true; // Accept all certificates
        };

    return IOClient(httpClient);
  }

  @override
  bool isMobile() {
    return Platform.isAndroid || Platform.isIOS;
  }

  @override
  void dummrumleuchte() async {
    try {
      var sender = await UDP.bind(Endpoint.any(port: Port.any));
      var dataLength = await sender.send(
        "blink".codeUnits,
        Endpoint.unicast(
          (await InternetAddress.lookup("NODE-F4C64E.lab")).first,
          port: const Port(5000),
        ),
      );
      sender.close();
      developer.log(
        "Gesendet: 'blink' an NODE-F4C64E.lab:5000, $dataLength Bytes",
      );
    } catch (e) {
      developer.log("Fehler beim Senden der UDP-Nachricht: $e");
    }
  }

  @override
  Future<List<ActiveHost>> scanLocalNetwork(BuildContext context) async {
    List<ActiveHost> arpResults = [];
    try {
      final interface = await NetInterface.localInterface();
      if (interface == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Keine Netzwerk-Schnittstelle gefunden oder fehlende Berechtigungen.",
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return arpResults;
      }

      // Start scanning and update results as they come in
      final stream = HostScannerService.instance.getAllPingableDevices(
        interface.networkId,
        timeoutInSeconds: 5, // Optional: adjust timeout
      );

      await for (final host in stream) {
        arpResults.add(ActiveHost(host.address, await host.getMacAddress()));
      }

      // Give a small delay to ensure all stream events are processed
      await Future.delayed(const Duration(milliseconds: 500));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Netzwerk-Scan abgeschlossen (${arpResults.length} Hosts gefunden)",
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      String errorMessage = "Netzwerk-Scan fehlgeschlagen: $e. ";
      if (e.toString().contains("LateInitializationError") ||
          e.toString().contains("PlatformException")) {
        errorMessage +=
            "Dies kann auf fehlende Berechtigungen (z.B. Standort) oder ein Problem mit der Netzwerk-Tools-Bibliothek hindeuten. Bitte stellen Sie sicher, dass alle erforderlichen Berechtigungen erteilt wurden und führen Sie 'flutter clean' sowie 'flutter pub get' aus.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return arpResults;
    }
    return arpResults;
  }

  @override
  void configureNetworkTools() async {
    await configureNetworkToolsFlutter(
      (await getApplicationDocumentsDirectory()).path,
    );
  }
}
