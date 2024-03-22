import 'dart:convert';
import 'dart:ffi';

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
import 'package:flutter_appauth/flutter_appauth.dart';

const hce = MethodChannel("hce");
const clientId = 'openlab-app';
const issuer = 'https://keycloak.lab.weltraumpflege.org/realms/OpenLab';
const redirect = 'de.openlab.openlabflutter:/oauthredirect';
const scopes = ['openid'];

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

  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  @override
  void initState() {
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

  Future<void> getAccessToken() async {
    String? accessToken = await loginKeykloak();
    if (accessToken != null) {
      print("Aaaaaaaaaaaa:" + accessToken);
      var result = await hce
          .invokeMethod<bool>("accessToken", {"accessToken": accessToken});
    }
  }

  Future<String?> loginKeykloak() async {
    print("trying keykloak login");
    final AuthorizationTokenResponse? result =
        await _appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        'openlab-app',
        'de.openlab.openlabflutter:/oauthredirect',
        serviceConfiguration: AuthorizationServiceConfiguration(
            authorizationEndpoint:
                "https://keycloak.lab.weltraumpflege.org/realms/OpenLabTest/protocol/openid-connect/auth",
            tokenEndpoint:
                "https://keycloak.lab.weltraumpflege.org/realms/OpenLabTest/protocol/openid-connect/token",
            endSessionEndpoint:
                "https://keycloak.lab.weltraumpflege.org/realms/OpenLabTest/protocol/openid-connect/logout"),
        clientSecret: 'VcJGq5LUZBg37nrbSEnwWOSRMKJtrlOe',
        issuer: issuer,
        scopes: scopes,
      ),
    );
    if (result != null) {
      await setRefreshTokenAndAccessToken(
          result!.refreshToken, result!.accessToken);
      return result!.accessToken;
    }
    print("After keykloadk login ");
  }

  Future<void> setRefreshTokenAndAccessToken(
      String? refreshToken, String? accessToken) async {
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
        iosAlertMessage: "Scan your tag");
    print(jsonEncode(tag));
  }

  Future<void> emulate() async {
    var result = await hce.invokeMethod<bool>("startHCE");
    if (result == true) {
      print("Yeah called the method");
      var result = await hce
          .invokeMethod<bool>("accessToken", {"accessToken": accessToken});
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              "Bitte gib erst in den Einstellungen deinen Username und dein Passwort ein!")));
    }
  }

  void outerDoor() async {
    checkCreds();
    String basicAuth =
        'Basic ' + base64Encode(utf8.encode('$username:$password'));
    await http.post(Uri.parse("http://airlock.lab:3000/open/outerdoor"),
        headers: {
          'authorization': basicAuth,
          'Access-Control-Allow-Origin': '*'
        });
  }

  void innerDoor() async {
    checkCreds();
    String basicAuth =
        'Basic ' + base64Encode(utf8.encode('$username:$password'));
    await http.post(Uri.parse("http://airlock.lab:3000/open/innerdoor"),
        headers: {
          'authorization': basicAuth,
          'Access-Control-Allow-Origin': '*'
        });
  }

  @override
  Widget build(BuildContext context) {
    ButtonStyle borderStyle = ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        foregroundColor: Theme.of(context).primaryColor,
        textStyle: TextStyle(
            fontSize: Theme.of(context).textTheme.headlineMedium!.fontSize));

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ElevatedButton(
                      style: borderStyle,
                      onPressed: outerDoor,
                      child: Text(
                        "Außentüre",
                      )),
                ),
                Expanded(
                    child: ElevatedButton(
                        style: borderStyle,
                        onPressed: innerDoor,
                        child: Text(
                          "Innentüre",
                        )))
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
              onPressed: connectWifi, child: const Text("Mit Wifi verbinden")),
        ),
      ],
    );
  }
}
