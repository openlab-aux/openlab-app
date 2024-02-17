import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:wifi_iot/wifi_iot.dart';
import 'dart:io' show Platform;
import 'package:retry/retry.dart';

class OpenDoor extends StatefulWidget {
  @override
  _OpenDoorState createState() => _OpenDoorState();
}

class _OpenDoorState extends State<OpenDoor> {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  String username = "";
  String password = "";
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initValues();
    });
  }

  void initValues() async {
    String u = await storage.read(key: "username") ?? "";
    String p = await storage.read(key: "password") ?? "";
    setState(() {
      this.username = u;
      this.password = p;
    });
  }

  void connectWifi() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await retry(() async {
          await WiFiForIoTPlugin.setEnabled(true, shouldOpenSettings: false);
          await WiFiForIoTPlugin.connect("Labor 2.0",
              password: "nerdhoehle2", security: NetworkSecurity.WPA);
        }, retryIf: (e) => WiFiForIoTPlugin.getSSID() != "Labor 2.0");
      }
    } catch (e) {
      print(e);
    }
  }

  void outerDoor() async {
    String basicAuth =
        'Basic ' + base64Encode(utf8.encode('$username:$password'));
    await http.post(Uri.parse("http://172.16.0.248:3000/open/outerdoor"),
        headers: {
          'authorization': basicAuth,
          'Access-Control-Allow-Origin': '*'
        });
  }

  void innerDoor() async {
    String basicAuth =
        'Basic ' + base64Encode(utf8.encode('$username:$password'));
    await http.post(Uri.parse("http://172.16.0.248:3000/open/innerdoor"),
        headers: {
          'authorization': basicAuth,
          'Access-Control-Allow-Origin': '*'
        });
  }

  @override
  Widget build(BuildContext context) {
    ButtonStyle borderStyle = ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero));

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
                      child: const Text("Außentüre")),
                ),
                Expanded(
                    child: ElevatedButton(
                        style: borderStyle,
                        onPressed: innerDoor,
                        child: const Text("Innentüre")))
              ],
            ),
          ),
        ),
        ElevatedButton(
            onPressed: connectWifi, child: const Text("Mit Wifi verbinden")),
      ],
    );
  }
}
