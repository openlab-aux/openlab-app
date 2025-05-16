import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Settings extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  String username = "";
  String password = "";
  String nickname = "";
  final storage = new FlutterSecureStorage();
  TextEditingController usernameController = new TextEditingController();
  TextEditingController passwordController = new TextEditingController();
  TextEditingController nicknameController = new TextEditingController();
  @override
  void initState() {
    super.initState();
    print("Initstate");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("WidgetBinding");
      initValues();
    });
  }

  void initValues() async {
    String u = await storage.read(key: "username") ?? "";
    String p = await storage.read(key: "password") ?? "";
    String n = await storage.read(key: "nickname") ?? "ReplaceMe";
    setState(() {
      this.username = u;
      this.password = p;
      this.nickname = n;
      usernameController.text = u;
      passwordController.text = p;
      nicknameController.text = n;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        children: [
          Text(
            "Einstellungen",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 8.0),
            child: TextFormField(
              controller: usernameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                label: Text("Authentik Username"),
              ),
              onChanged:
                  (value) async => {
                    setState(() {
                      username = value;
                    }),
                    await storage.write(key: "username", value: value),
                  },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                label: Text("Authentik Password"),
              ),
              onChanged:
                  (value) async => {
                    setState(() {
                      password = password;
                    }),
                    await storage.write(key: "password", value: value),
                  },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: nicknameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                label: Text("Nickname auf der Strichliste"),
              ),
              onChanged:
                  (value) async => {
                    setState(() {
                      nickname = nickname;
                    }),
                    await storage.write(key: "nickname", value: value),
                  },
            ),
          ),
        ],
      ),
    );
  }
}
