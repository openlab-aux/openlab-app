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

    if (accessToken != null || accessToken!.isNotEmpty) {
      DateTime expirationDate = JwtDecoder.getExpirationDate(accessToken);
      var result = await hce.invokeMethod<bool>("accessToken", {
        "accessToken": accessToken,
        "expirationDate": expirationDate.toIso8601String(),
      });
      "Empty access token again";
    }
    return accessToken;
    // if (accessToken.isEmpty) {
    //   String? accessToken = await loginKeykloak();
    //   setState(() {
    //     this.accessToken = accessToken ?? "";
    //   });
    //   if (accessToken != null || accessToken!.isNotEmpty) {
    //     print("Aaaaaaaaaaaa:" + (accessToken ?? ""));
    //     var result = await hce
    //         .invokeMethod<bool>("accessToken", {"accessToken": accessToken});
    //     print("after aaaaaaaaa");
    //   } else {
    //     "Empty access token again";
    //   }
    // } else {
    //   print("Using saved access token");
    //   var result = await hce
    //       .invokeMethod<bool>("accessToken", {"accessToken": this.accessToken});
    // }
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
    // // change port here
    // var port = 0;
    // // change data to transmit here
    // var data = [12, 34, 56, 78, 90, 0xab, 0xcd, 0xef, 90, 00];
    // await NfcHce.addApduResponse(port, data);
    // print("Emulated the data");
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

    // NfcHce.stream.listen((command) {
    //   print("Steeeeeeeeeeeeeeeeeeeeaaaaaaam");
    //   print(command);
    //   setState(() => nfcApduCommand = command);
    // });
  }

  void connectWifi() async {
    await emulate();
    return;
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
    } catch (e) {
      print(e);
    }
  }

  void checkCreds() {
    if (username.isEmpty && password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Bitte gib erst in den Einstellungen deinen Username und dein Passwort ein!",
          ),
        ),
      );
    }
  }

  Future<void> buzz(BuzzType buzztype) async {
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
    } catch (e) {
      print('Error: $e');
    } finally {
      client.close(); // Don't forget to close the client
    }
  }

  void printWrapped(String text) {
    final pattern = new RegExp('.{1,800}'); // 800 is the size of each chunk
    pattern.allMatches(text).forEach((match) => print(match.group(0)));
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle borderStyle = ElevatedButton.styleFrom(
      textStyle: TextStyle(
        fontSize: Theme.of(context).textTheme.headlineMedium!.fontSize,
      ),
    );

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 2, 0),
                    child: ElevatedButton(
                      style: borderStyle,
                      onPressed: () async => await buzz(BuzzType.outer),
                      child: Text(
                        "Außentüre öffnen",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(2, 0, 0, 0),
                    child: ElevatedButton(
                      style: borderStyle,
                      onPressed: () async => buzz(BuzzType.inner),
                      child: Text(
                        "Innentüre öffnen",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 0, 4.0, 16),
                child: ElevatedButton(
                  onPressed: connectWifi,
                  child: const Text("Mit Wifi verbinden"),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4.0, 0, 16.0, 16),
                child: ElevatedButton(
                  onPressed: getAccessToken,
                  child: const Text("Authentik login"),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
