import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:oidc_default_store/oidc_default_store.dart';
import 'package:openlabflutter/main.dart';
import 'dart:io' show Platform;
import 'package:retry/retry.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:oidc/oidc.dart';
import 'package:oidc_core/oidc_core.dart';
import 'package:http/io_client.dart';

const hce = MethodChannel("hce");

enum BuzzType { inner, outer }

class OpenDoor extends StatefulWidget {
  OidcUserManager? oidcManager;
  Function getAccessToken;
  OpenDoor({required this.oidcManager, required this.getAccessToken});

  @override
  _OpenDoorState createState() => _OpenDoorState();
}

class _OpenDoorState extends State<OpenDoor> {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  bool _isLoading = false;
  bool innerDoorLoading = false;
  bool outerDoorLoading = false;

  http.Client createHttpClient() {
    final httpClient = HttpClient();
    // Disable certificate verification
    httpClient.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
          return true; // Accept all certificates
        };

    return IOClient(httpClient);
  }

  Future<String?> getAccessToken() async {
    return await widget.getAccessToken();
  }

  @override
  void initState() {
    super.initState();
    if (widget.oidcManager != null) {
      widget.oidcManager!.init();
      this.widget.oidcManager!.userChanges().listen((user) {});
    }
    ;
    hce.setMethodCallHandler((MethodCall call) async {
      print(call.method);
      switch (call.method) {
        case "getAccessToken":
          await getAccessToken();
          print("Finished getting access Token");
          break;
        case "widgetBuzz":
          // Handle widget buzz calls
          final Map<String, dynamic> args = Map<String, dynamic>.from(
            call.arguments,
          );
          final String? buzzType = args['type'];
          if (buzzType != null) {
            print("Widget buzz called with type: $buzzType");
            await handleWidgetBuzz(buzzType);
          }
          break;
      }
    });
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> handleWidgetBuzz(String buzzType) async {
    try {
      if (widget.oidcManager != null) {
        widget.oidcManager!.init();
        this.widget.oidcManager!.userChanges().listen((user) {});
      }
      await Future.delayed(Duration(milliseconds: 1000));
      // Check if user is logged in by trying to get access token
      String? accessToken = await getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        // Try to automatically login
        print("User not logged in, attempting auto-login...");

        try {
          accessToken = await getAccessToken();

          if (accessToken == null || accessToken.isEmpty) {
            print("Auto-login failed");
            _showErrorSnackBar("Login fehlgeschlagen");
            return;
          }
        } catch (e) {
          print("Auto-login exception: $e");
          _showErrorSnackBar("Login-Fehler: $e");
          return;
        }
      }

      // User is logged in, proceed with buzzing
      if (buzzType == "inner") {
        await buzz(BuzzType.inner);
      } else if (buzzType == "outer") {
        await buzz(BuzzType.outer);
      }
    } catch (e, s) {
      print("Error handling widget buzz: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Fehler beim Öffnen der Türe: $e $s"),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> readNFC() async {
    var availability = await FlutterNfcKit.nfcAvailability;
    if (availability != NFCAvailability.available) {
      // oh-no
      print("NFC not available");
    } // timeout only works on Android, while the latter two messages are only for iOS
    var tag = await FlutterNfcKit.poll(
      timeout: Duration(seconds: 10),
      iosMultipleTagMessage: "Multiple tags found!",
      iosAlertMessage: "Scan your tag",
    );
    print(jsonEncode(tag));
  }

  Future<void> emulate() async {
    if (widget.oidcManager == null) return;
    var result = await hce.invokeMethod<bool>("startHCE");
    if (result == true && this.widget.oidcManager!.currentUser != null) {
      print("Yeah called the method");
      final user = widget.oidcManager?.currentUser;
      final idToken = user?.token.idToken;

      if (idToken == null) {
        print("Error: idToken is null");
        return;
      }

      await hce.invokeMethod<bool>("accessToken", {"accessToken": idToken});
    } else {
      print("Nonononono");
    }
  }

  void connectWifi() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await retry(() async {
          await WiFiForIoTPlugin.setEnabled(true, shouldOpenSettings: false);
          print(await WiFiForIoTPlugin.isEnabled());
          bool connected = await WiFiForIoTPlugin.connect(
            "Labor 2.0",
            password: "nerdhoehle2",
            security: NetworkSecurity.WPA,
            withInternet: false,
            timeoutInSeconds: 10,
            joinOnce: (Platform.isIOS) ? false : true,
          );
          print(await WiFiForIoTPlugin.isConnected());
          await WiFiForIoTPlugin.forceWifiUsage(true);
          print(await WiFiForIoTPlugin.isConnected());
          print(await WiFiForIoTPlugin.getSSID());
        }, retryIf: (e) => WiFiForIoTPlugin.getSSID() != "Labor 2.0");
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Erfolgreich mit WiFi verbunden"),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("WiFi-Verbindung fehlgeschlagen"),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> buzz(BuzzType buzztype) async {
    setState(() {
      _isLoading = true;
    });
    final client = createHttpClient();
    String? accessToken = await getAccessToken();
    print("https://airlockng.lab/api/buzz/${buzztype.name}?duration=500");
    printWrapped(accessToken ?? "");

    try {
      final response = await client.post(
        Uri.parse(
          "https://airlockng.lab/api/buzz/${buzztype.name}?duration=500",
        ),
        headers: {"X-Authorization": accessToken ?? ""},
      );

      if (response.request != null) {
        printWrapped(response.request!.headers.toString());
      } else {
        print("Response request is null");
      }
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "${buzztype.name == 'outer' ? 'Außentüre' : 'Innentüre'} geöffnet",
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Fehler beim Öffnen der Türe"),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      print('Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Netzwerkfehler beim Öffnen der Türe"),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      client.close();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void printWrapped(String text) {
    final pattern = new RegExp('.{1,800}'); // 800 is the size of each chunk
    pattern.allMatches(text).forEach((match) => print(match.group(0)));
  }

  Widget _buildDoorCard({
    required String title,
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return Card(
      elevation: 0,
      color: _isLoading ? Theme.of(context).disabledColor : backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: InkWell(
        onTap: _isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 160,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isLoading
                      ? Theme.of(context).dividerColor
                      : Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (_isLoading) ...[
                const SizedBox(width: 16),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color:
                          Theme.of(context).colorScheme.primary ==
                              backgroundColor
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 0,
      color: _isLoading
          ? Theme.of(context).disabledColor
          : Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: InkWell(
        onTap: _isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isLoading
                      ? Theme.of(context).dividerColor
                      : Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (_isLoading) ...[
                const SizedBox(width: 16),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Action cards
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(
                  child: _buildActionCard(
                    title: "Mit WiFi verbinden",
                    icon: Icons.wifi,
                    onPressed: connectWifi,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _buildActionCard(
                    title: "Authentik Login",
                    icon: Icons.login,
                    onPressed: getAccessToken,
                  ),
                ),
              ],
            ),
          ),

          // Door control cards
          const SizedBox(height: 5),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: SizedBox.expand(
                      // <-- Use SizedBox.expand here
                      child: _buildDoorCard(
                        title: "Außentüre\nöffnen",
                        icon: Icons.door_front_door,
                        onPressed: () => buzz(BuzzType.outer),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: SizedBox.expand(
                      // <-- Use SizedBox.expand here
                      child: _buildDoorCard(
                        title: "Innentüre\nöffnen",
                        icon: Icons.door_back_door,
                        onPressed: () => buzz(BuzzType.inner),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondaryContainer,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
