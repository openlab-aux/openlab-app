import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
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
const clientId = 'RX1Tts6xiTxS0jMcYvTTBTKejHQpCKwWyoQwF8JC';
const clientSecret =
    '7buahQTaCr1cPMMgnMylkdcXlycfJXbmCnodLYQKN5M9N05t5MGhFXgR4Gygcxw5p1bUVna08OeMoSAD747fMDsH2KocIHWGQxl7nF9VnUOa952hUyqzqjnvbfXQlUIr';
const redirect = 'de.openlab.openlabflutter:/oauth2redirect';
const String logout = 'de.openlab.openlabflutter:/logout';
const wellKnownUrl =
    "https://auth.openlab-augsburg.de/application/o/airlock/.well-known/openid-configuration";
final store = OidcMemoryStore();

enum BuzzType { inner, outer }

class OpenDoor extends StatefulWidget {
  @override
  _OpenDoorState createState() => _OpenDoorState();
}

class _OpenDoorState extends State<OpenDoor> {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  String username = "";
  String password = "";
  String refreshToken = "";
  String accessToken = "";
  bool _isLoading = false;

  // this will be changed in the NfcHce.stream listen callback
  final manager = OidcUserManager.lazy(
    discoveryDocumentUri: Uri.parse(wellKnownUrl),
    clientCredentials: const OidcClientAuthentication.clientSecretBasic(
      clientId: clientId,
      clientSecret: clientSecret,
    ),
    store: store,
    settings: OidcUserManagerSettings(
      //get any available port
      redirectUri: Uri.parse(redirect),
      postLogoutRedirectUri: Uri.parse(logout),
      scope: ['openid', 'profile', 'email', 'groups'],
    ),
  );

  http.Client createHttpClient() {
    final httpClient = HttpClient();
    // Disable certificate verification
    httpClient.badCertificateCallback = (
      X509Certificate cert,
      String host,
      int port,
    ) {
      return true; // Accept all certificates
    };

    return IOClient(httpClient);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initValues();
    });

    hce.setMethodCallHandler((MethodCall call) async {
      print(call.method);
      switch (call.method) {
        case "getAccessToken":
          await getAccessToken();
          print("Finished getting access Token");
      }
    });
  }

  Future<String?> getAccessToken() async {
    String? accessToken = await loginOIDC();

    if (accessToken != null && accessToken.isNotEmpty) {
      DateTime expirationDate = JwtDecoder.getExpirationDate(accessToken);
      var result = await hce.invokeMethod<bool>("accessToken", {
        "accessToken": accessToken,
        "expirationDate": expirationDate.toIso8601String(),
      });
      print("Access token sent to native layer");
    } else {
      print("Access token is null or empty");
    }

    return accessToken;
  }

  Future<String?> loginOIDC() async {
    print("Trying keycloak login on Android");
    if (!manager.didInit) {
      await manager.init();
    }

    try {
      // Check if user is already logged in
      if (manager.currentUser != null) {
        // Check if token is expired based on expiration time
        final Duration? expiresIn = manager.currentUser?.token.expiresIn;

        if (expiresIn != null && expiresIn.isNegative) {
          print("User already logged in with valid token");
          return manager.currentUser!.token.idToken;
        }

        // Token is expired, try refreshing
        print("Token expired, attempting refresh");
        try {
          final refreshedUser = await manager.refreshToken();
          if (refreshedUser != null) {
            print("Token refreshed successfully");
            await setRefreshTokenAndAccessToken(
              refreshedUser.token.refreshToken,
              refreshedUser.token.idToken,
            );
            return refreshedUser.token.idToken;
          }
        } catch (e) {
          print("Token refresh failed: $e");
          // Continue to new login flow
        }
      }

      // Initiate login process
      print("Initiating new login flow");
      final OidcUser? user = await manager.loginAuthorizationCodeFlow();

      if (user != null) {
        await setRefreshTokenAndAccessToken(
          user.token.refreshToken,
          user.token.idToken,
        );
        return user.token.idToken;
      } else {
        print("Login failed - user is null");
        return null;
      }
    } catch (e, stackTrace) {
      print("OIDC login error: $e");
      print("Stack trace: $stackTrace");
      return null;
    }
  }

  Future<void> setRefreshTokenAndAccessToken(
    String? refreshToken,
    String? accessToken,
  ) async {
    await storage.write(key: "refreshToken", value: refreshToken);
    setState(() {
      refreshToken = refreshToken ?? "";
      accessToken = accessToken ?? "";
    });
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
    var result = await hce.invokeMethod<bool>("startHCE");
    if (result == true) {
      print("Yeah called the method");
      var result = await hce.invokeMethod<bool>("accessToken", {
        "accessToken": accessToken,
      });
    } else {
      print("Nonononono");
    }
  }

  void initValues() async {
    String u = await storage.read(key: "username") ?? "";
    String p = await storage.read(key: "password") ?? "";
    String r = await storage.read(key: "refreshToken") ?? "";
    await manager.init();
    setState(() {
      this.username = u;
      this.password = p;
      this.refreshToken = r;
    });
  }

  void connectWifi() async {
    setState(() {
      _isLoading = true;
    });

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

  void checkCreds() {
    if (username.isEmpty && password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Bitte gib erst in den Einstellungen deinen Username und dein Passwort ein!",
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
        headers: {"X-Authorization": accessToken!},
      );
      printWrapped(response.request!.headers.toString());
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
      color: backgroundColor,
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
              Icon(icon, size: 48, color: foregroundColor),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
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
      color: Theme.of(context).colorScheme.surfaceContainerLow,
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
                  color: Theme.of(context).colorScheme.primaryContainer,
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
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
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
          // Door control cards
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildDoorCard(
                      title: "Außentüre\nöffnen",
                      icon: Icons.door_front_door,
                      onPressed: () => buzz(BuzzType.outer),
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      foregroundColor:
                          Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _buildDoorCard(
                      title: "Innentüre\nöffnen",
                      icon: Icons.door_back_door,
                      onPressed: () => buzz(BuzzType.inner),
                      backgroundColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                      foregroundColor:
                          Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

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
        ],
      ),
    );
  }
}
