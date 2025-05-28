import 'package:flutter/material.dart';
import 'package:openlabflutter/open_door.dart';
import 'package:openlabflutter/presence.dart';
import 'package:openlabflutter/projects.dart';
import 'package:openlabflutter/settings.dart';
import 'dart:typed_data';

import 'package:openlabflutter/strichliste.dart';
import 'package:openlabflutter/theme.dart';

void main() async {
  // WidgetsFlutterBinding.ensureInitialized();

  // _nfcState = await NfcHce.checkDeviceNfcState();

  // if (_nfcState == NfcState.enabled) {
  //   await NfcHce.init(
  //     // AID that match at least one aid-filter in apduservice.xml
  //     // In my case it is A000DADADADADA.
  //     aid: Uint8List.fromList([0xD2, 0x76, 0x00, 0x00, 0x85, 0x01, 0x00]),
  //     // next parameter determines whether APDU responses from the ports
  //     // on which the connection occurred will be deleted.
  //     // If `true`, responses will be deleted, otherwise won't.
  //     permanentApduResponses: false,
  //     // next parameter determines whether APDU commands received on ports
  //     // to which there are no responses will be added to the stream.
  //     // If `true`, command won't be added, otherwise will.
  //     listenOnlyConfiguredPorts: false,
  //   );
  //   print("NFC HCE Initialized");
  // } else {
  //   print("Cant enable NFC HCE");
  // }

  WidgetsFlutterBinding.ensureInitialized();

  runApp(const Openlab());
}

class Openlab extends StatefulWidget {
  const Openlab({super.key});

  @override
  State<Openlab> createState() => _OpenlabState();
}

class _OpenlabState extends State<Openlab> {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Openlab',
      theme: OpenLabTheme.lightTheme,
      darkTheme: OpenLabTheme.darkTheme,
      home: MainWidget(),
    );
  }
}

class MainWidget extends StatefulWidget {
  @override
  _MainWidgetState createState() => _MainWidgetState();
}

class _MainWidgetState extends State<MainWidget> {
  int _selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    Widget widget = OpenDoor();
    switch (_selectedIndex) {
      case 0:
        widget = OpenDoor();
        break;
      case 1:
        widget = Presence();
        break;
      case 2:
        widget = Strichliste();
        break;
      case 3:
        widget = Projects();
        break;
      case 4:
        widget = Settings();
        break;
      default:
        widget = OpenDoor();
    }

    return Scaffold(
      body: SafeArea(child: widget),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.shifting,
        currentIndex: _selectedIndex,
        onTap: (value) {
          setState(() {
            _selectedIndex = value;
          });
        },
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Tür'),
          BottomNavigationBarItem(icon: Icon(Icons.business), label: 'Präsenz'),
          BottomNavigationBarItem(icon: Icon(Icons.euro), label: 'Strichliste'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Projekte'),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Einstellungen',
          ),
        ],
      ),
    );
  }
}
