import 'package:flutter/material.dart';
import 'package:openlab_flutter/open_door.dart';
import 'package:openlab_flutter/presence.dart';
import 'package:openlab_flutter/settings.dart';

void main() {
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
        title: 'Flutter Demo',
        theme: ThemeData(
          // This is the theme of your application.
          //
          // TRY THIS: Try running your application with "flutter run". You'll see
          // the application has a blue toolbar. Then, without quitting the app,
          // try changing the seedColor in the colorScheme below to Colors.green
          // and then invoke "hot reload" (save your changes or press the "hot
          // reload" button in a Flutter-supported IDE, or press "r" if you used
          // the command line to start the app).
          //
          // Notice that the counter didn't reset back to zero; the application
          // state is not lost during the reload. To reset the state, use hot
          // restart instead.
          //
          // This works for code too, not just values: Most code changes can be
          // tested with just a hot reload.
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: MainWidget());
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
        widget = Settings();
        break;
      default:
        widget = OpenDoor();
    }

    return Scaffold(
        body: widget,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (value) {
            setState(() {
              _selectedIndex = value;
            });
          },
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Tür',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.business),
              label: 'Präsenz',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.school),
              label: 'Settings',
            ),
          ],
        ));
  }
}
