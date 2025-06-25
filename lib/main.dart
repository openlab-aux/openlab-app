import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:network_tools_flutter/network_tools_flutter.dart';
import 'package:oidc/oidc.dart';
import 'package:oidc_default_store/oidc_default_store.dart';
import 'package:openlabflutter/calendar.dart';
import 'package:openlabflutter/fun.dart';
import 'package:openlabflutter/open_door.dart';
import 'package:openlabflutter/presence.dart';
import 'package:openlabflutter/projects.dart';
import 'package:openlabflutter/settings.dart';
import 'dart:typed_data';

import 'package:openlabflutter/strichliste.dart';
import 'package:openlabflutter/theme.dart';
import 'package:path_provider/path_provider.dart';

const airlockClientId = 'RX1Tts6xiTxS0jMcYvTTBTKejHQpCKwWyoQwF8JC';
const airlockWellKnownUrl =
    "https://auth.openlab-augsburg.de/application/o/airlock/.well-known/openid-configuration";

const airlockRedirectUrl = 'de.openlab.openlabflutter:/oauth2redirect';
const String airlockLogoutUrl = 'de.openlab.openlabflutter:/logout';

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

  await configureNetworkToolsFlutter(
    (await getApplicationDocumentsDirectory()).path,
  );
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

  final store = OidcDefaultStore();
  OidcUserManager? airlockOidcManager;
  OidcUserManager? presenceOidcManager;
  @override
  void initState() {
    super.initState();
    initOidc();
  }

  Future<void> initOidc() async {
    if (airlockOidcManager != null && airlockOidcManager!.didInit) return;

    final manager = OidcUserManager.lazy(
      discoveryDocumentUri: Uri.parse(airlockWellKnownUrl),
      clientCredentials: const OidcClientAuthentication.none(
        clientId: airlockClientId,
      ),
      store: store,
      settings: OidcUserManagerSettings(
        redirectUri: Uri.parse(airlockRedirectUrl),
        postLogoutRedirectUri: Uri.parse(airlockLogoutUrl),
        scope: ['openid', 'profile', 'email', 'groups'],
        supportOfflineAuth: true,
      ),
    );

    try {
      await manager.init(); // ❗ Required
      airlockOidcManager = manager;
      print("OIDC manager initialized.");
    } catch (e, st) {
      print("OIDC manager init failed: $e");
      print(st);
    }
  }

  Future<String?> getAccessToken() async {
    await initOidc();

    if (airlockOidcManager == null || !airlockOidcManager!.didInit) {
      print("OIDC manager not ready");
      return null;
    }

    String? accessToken = await loginOIDC();
    if (accessToken != null && accessToken.isNotEmpty) {
      DateTime expirationDate = JwtDecoder.getExpirationDate(accessToken);
      hce.invokeMethod<bool>("accessToken", {
        "accessToken": accessToken,
        "expirationDate": expirationDate.toIso8601String(),
      });
      print("Access token sent to native layer");
    } else {
      print("Access token is null or empty");
    }

    return accessToken;
  }

  Future<String?> loginAuthorizationCodeFlow() async {
    await initOidc(); // Ensure fully initialized

    if (airlockOidcManager == null) {
      print("airlockOidcManager is still null after init");
      return null;
    }

    final OidcUser? user = await airlockOidcManager!
        .loginAuthorizationCodeFlow();
    if (user != null) {
      return user.token.idToken;
    } else {
      print("Login failed - user is null");
      return null;
    }
  }

  Future<String?> loginOIDC() async {
    await initOidc();

    if (airlockOidcManager == null || !airlockOidcManager!.didInit) {
      print("OIDC manager not ready");
      return null;
    }

    try {
      if (airlockOidcManager!.currentUser != null &&
          airlockOidcManager!.currentUser!.token.idToken != null) {
        final expirationDate = JwtDecoder.getExpirationDate(
          airlockOidcManager!.currentUser!.token.idToken!,
        );

        if (expirationDate.compareTo(DateTime.now()) >= 0) {
          print("User already logged in with valid token");
          return airlockOidcManager!.currentUser!.token.idToken;
        }

        print("Token expired, attempting refresh");
        try {
          final refreshedUser = await airlockOidcManager!.refreshToken();
          if (refreshedUser != null) {
            print("Token refreshed successfully");
            return refreshedUser.token.idToken;
          } else {
            print("Token refresh failed");
            return loginAuthorizationCodeFlow();
          }
        } catch (e) {
          print("Token refresh error: $e");
          return loginAuthorizationCodeFlow();
        }
      } else {
        print("Logging in user");
        return loginAuthorizationCodeFlow();
      }
    } catch (e, stackTrace) {
      print("OIDC login error: $e");
      print("Stack trace: $stackTrace");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget widget;
    switch (_selectedIndex) {
      case 0:
        widget = OpenDoor(
          oidcManager: airlockOidcManager,
          getAccessToken: getAccessToken,
        );
        break;
      case 1:
        widget = Presence(
          oidcManager: airlockOidcManager,
          getAccessToken: getAccessToken,
        );
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
      case 5:
        widget = FunWidget();
        break;
      case 6:
        widget = ICalCalendarWidget(
          icalUrl: 'https://www.openlab-augsburg.de/calendar/ical',
        );
      default:
        widget = OpenDoor(
          oidcManager: airlockOidcManager,
          getAccessToken: getAccessToken,
        );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_getPageTitle())),
      body: SafeArea(child: widget),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.white,
                image: DecorationImage(
                  image: AssetImage('assets/icon/icon.png'),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(0, 100, 0, 0),
                child: Text(
                  'OpenLab Augsburg e.V.',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Tür'),
              selected: _selectedIndex == 0,
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.business),
              title: const Text('Präsenz'),
              selected: _selectedIndex == 1,
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.euro),
              title: const Text('Strichliste'),
              selected: _selectedIndex == 2,
              onTap: () {
                setState(() {
                  _selectedIndex = 2;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Projekte'),
              selected: _selectedIndex == 3,
              onTap: () {
                setState(() {
                  _selectedIndex = 3;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.school),
              title: const Text('Einstellungen'),
              selected: _selectedIndex == 4,
              onTap: () {
                setState(() {
                  _selectedIndex = 4;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.celebration),
              title: const Text('Spass'),
              selected: _selectedIndex == 5,
              onTap: () {
                setState(() {
                  _selectedIndex = 5;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Tür';
      case 1:
        return 'Präsenz';
      case 2:
        return 'Strichliste';
      case 3:
        return 'Projekte';
      case 4:
        return 'Einstellungen';
      case 5:
        return 'Spaß';
      case 6:
        return 'Kalender';
      default:
        return 'Tür';
    }
  }
}
