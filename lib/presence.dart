import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:duration_picker/duration_picker.dart';
import 'package:direct_select/direct_select.dart';

class PresenceResponse {
  final Map<String, DateTime> users;

  const PresenceResponse({
    required this.users,
  });

  factory PresenceResponse.fromJson(Map<String, dynamic> json) {
    Map<String, String> users = Map.from(json['users']);
    return PresenceResponse(
        users: users.map((key, value) => MapEntry(key, DateTime.parse(value))));
  }
}

enum ComingType { Gammeln, Connecten, Fokus }

class Coming {
  final ComingType type;
  final DateTime when;
  final DateTime edited;

  const Coming({required this.type, required this.when, required this.edited});
}

class ComingResponse {
  final Map<String, Coming> users;

  const ComingResponse({
    required this.users,
  });

  factory ComingResponse.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> users = Map.from(json['users']);
    return ComingResponse(
        users: users.map((key, value) => MapEntry(
            key,
            Coming(
                type: ComingType.values.byName(value['coming_type']),
                when: DateTime.parse(value['when']),
                edited: DateTime.parse(value['edited'])))));
  }
}

class Presence extends StatefulWidget {
  @override
  _PresenceState createState() => _PresenceState();
}

class _PresenceState extends State<Presence> {
  final String apiUrl = "https://openlapp.lab.weltraumpflege.org";
  PresenceResponse? presence;
  ComingResponse? coming;
  String nickname = "ReplaceMe";
  bool loggedIn = false;
  bool planingToCome = false;
  Duration whenICome = Duration(minutes: 30);
  ComingType comingType = ComingType.Gammeln;

  final storage = new FlutterSecureStorage();
  RefreshController _refreshController =
      RefreshController(initialRefresh: true);

  @override
  void initState() {
    super.initState();
  }

  void refresh() {
    loadPresence();
    loadComing();
    _refreshController.refreshCompleted();
    _refreshController.loadComplete();
  }

  void loadPresence() async {
    try {
      http.Response response = await http.get(Uri.parse(apiUrl + "/presence"));
      if (response.statusCode == 200) {
        nickname = await storage.read(key: "nickname") ?? "ReplaceMe";
        setState(() {
          Map<String, dynamic> body =
              jsonDecode(response.body) as Map<String, dynamic>;
          presence = PresenceResponse.fromJson(body);
          loggedIn = false;
          for (String user in presence!.users.keys) {
            if (user == nickname) {
              loggedIn = true;
            }
          }
        });
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  void loadComing() async {
    try {
      http.Response response = await http.get(Uri.parse(apiUrl + "/coming"));
      if (response.statusCode == 200) {
        nickname = await storage.read(key: "nickname") ?? "ReplaceMe";
        setState(() {
          Map<String, dynamic> body =
              jsonDecode(response.body) as Map<String, dynamic>;
          coming = ComingResponse.fromJson(body);
          planingToCome = false;
          for (String user in coming!.users.keys) {
            if (user == nickname) {
              planingToCome = true;
            }
          }
        });
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    }
  }

  void logout() async {
    try {
      http.Response response = await http.delete(
          Uri.parse(apiUrl + "/presence"),
          body: jsonEncode({"nickname": nickname}),
          headers: {
            "Content-Type": "application/json",
            'Access-Control-Allow-Origin': '*'
          });
      if (response.statusCode == 200) {
        loadPresence();
      } else {
        print(response);
      }
    } catch (e) {
      print(e);
    }
  }

  void login() async {
    try {
      http.Response response = await http.put(Uri.parse(apiUrl + "/presence"),
          body: jsonEncode({"nickname": nickname}),
          headers: {
            "Content-Type": "application/json",
            'Access-Control-Allow-Origin': '*'
          });
      if (response.statusCode == 200) {
        loadPresence();
      } else {
        print(response);
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> comingBottomSheet() async {
    await showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateSetter) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                        "Wann kommst du denn?\nDreh öfters um Stunden zu selektieren."),
                  ),
                  DurationPicker(
                      duration: whenICome,
                      onChange: (value) {
                        setStateSetter(() {
                          whenICome = value;
                        });
                      }),
                  Text("Und was möchtest du tun?"),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DropdownButton<ComingType>(
                        value: comingType,
                        items: ComingType.values
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e.name),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setStateSetter(() {
                            if (value != null) {
                              comingType = value;
                            }
                          });
                        }),
                  )
                ],
              );
            },
          );
        });
  }

  void i_am_coming() async {
    await comingBottomSheet();

    try {
      DateTime whenTime = (DateTime.now().add(whenICome)).toUtc();
      http.Response response = await http.put(Uri.parse(apiUrl + "/coming"),
          body: jsonEncode({
            "nickname": nickname,
            "coming_type": comingType.name,
            "when":
                "${whenTime.day.toString().padLeft(2, "0")}.${whenTime.month.toString().padLeft(2, "0")}.${whenTime.year.toString().padLeft(2, "0")} ${whenTime.hour.toString().padLeft(2, "0")}:${whenTime.minute.toString().padLeft(2, "0")}:${whenTime.second.toString().padLeft(2, "0")}"
          }),
          headers: {
            "Content-Type": "application/json",
            'Access-Control-Allow-Origin': '*'
          });
      if (response.statusCode == 200) {
        loadComing();
      } else {
        print(response);
      }
    } catch (e) {
      print(e);
    }
  }

  void not_coming() async {
    try {
      http.Response response = await http.delete(Uri.parse(apiUrl + "/coming"),
          body: jsonEncode({"nickname": nickname}),
          headers: {
            "Content-Type": "application/json",
            'Access-Control-Allow-Origin': '*'
          });
      if (response.statusCode == 200) {
        loadComing();
      } else {
        print(response);
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget loginButton = Expanded(
      child: ElevatedButton(
          onPressed: () {
            if (loggedIn) {
              logout();
            } else {
              login();
            }
          },
          child: Text(loggedIn ? "Ausloggen" : "Einloggen")),
    );
    Widget comingButton = Expanded(
      child: ElevatedButton(
          onPressed: () {
            if (planingToCome) {
              not_coming();
            } else {
              i_am_coming();
            }
          },
          child: Text(planingToCome ? "Doch nicht ..." : "Ich komme!")),
    );
    if ((presence == null || coming == null) ||
        (presence!.users.isEmpty && coming!.users.isEmpty)) {
      return Stack(children: [
        SmartRefresher(
            controller: _refreshController,
            onRefresh: () => refresh(),
            onLoading: () => refresh(),
            enablePullDown: true,
            enablePullUp: true,
            header: WaterDropHeader(),
            child: Center(child: Text("Leider niemand da :("))),
        Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 50,
              width: double.infinity,
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [loginButton, comingButton]),
            )),
      ]);
    }
    return Stack(children: [
      SmartRefresher(
        controller: _refreshController,
        onRefresh: () => refresh(),
        onLoading: () => refresh(),
        enablePullDown: true,
        enablePullUp: true,
        header: WaterDropHeader(),
        child: Column(
          children: [
            Text("Aktuell im Lab",
                style: Theme.of(context).textTheme.headlineMedium),
            Expanded(
              flex: 1,
              child: Scrollbar(
                child: ListView(
                  children: [
                    for (MapEntry<String, DateTime> entry
                        in presence!.users.entries)
                      ListTile(
                        title: Text(entry.key),
                        trailing: Text(
                            "${entry.value.toLocal().hour.toString().padLeft(2, "0")}:${entry.value.toLocal().minute.toString().padLeft(2, "0")}"),
                      )
                  ],
                ),
              ),
            ),
            Divider(),
            Text("Hat vor zu kommen",
                style: Theme.of(context).textTheme.headlineMedium),
            Expanded(
              flex: 1,
              child: Scrollbar(
                child: ListView(
                  children: [
                    for (MapEntry<String, Coming> entry
                        in coming!.users.entries)
                      ListTile(
                        title: Text(entry.key),
                        leading: Text(entry.value.type.name),
                        trailing: Text(
                            "${entry.value.when.toLocal().hour.toString().padLeft(2, "0")}:${entry.value.when.toLocal().minute.toString().padLeft(2, "0")}"),
                      )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
      Positioned(
          bottom: 10,
          left: 0,
          right: 0,
          child: SizedBox(
            height: 50,
            width: double.infinity,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [loginButton, comingButton],
            ),
          )),
    ]);
  }
}
