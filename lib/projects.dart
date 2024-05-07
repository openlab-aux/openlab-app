import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:openlabflutter/strichliste.dart';
import 'package:http/http.dart' as http;
import 'package:openlabflutter/strichliste_add.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class Project {
  int id;
  String name;
  int balance;
  String updated;

  Project(this.id, this.name, this.balance, this.updated);
}

class Projects extends StatefulWidget {
  @override
  _ProjectsState createState() => _ProjectsState();
}

class _ProjectsState extends State<Projects> {
  List<Project>? projects;
  String username = "";
  Map<String, dynamic>? user;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  RefreshController _refreshController =
      RefreshController(initialRefresh: true);

  void initValues() async {
    String u = await storage.read(key: "nickname") ?? "";

    print("username: " + u);
    setState(() {
      this.username = u;
    });
    await update();
  }

  Future<void> update() async {
    Map<String, dynamic>? user = await getUser();
    print(user);
    setState(() {
      this.user = user;
    });

    List<Project>? projects = await getProjects();
    setState(() {
      this.projects = projects;
    });

    _refreshController.refreshCompleted();
  }

  Future<Map<String, dynamic>?> getUser() async {
    print(username);
    if (username.isEmpty) return null;
    var uri = Uri.parse(strichliste + "/user/search");
    uri = uri.replace(queryParameters: {"query": username});
    var result = await http.get(uri);
    if (result.statusCode == 200) {
      var body = jsonDecode(result.body) as Map<String, dynamic>;
      print(body);
      return body["users"]
          .where((e) => !e["name"].toString().startsWith("P-"))
          .first;
    } else {
      return null;
    }
  }

  Future<List<Project>?> getProjects() async {
    var uri = Uri.parse(strichliste + "/user");
    var result = await http.get(uri);
    if (result.statusCode == 200) {
      var body = jsonDecode(result.body) as Map<String, dynamic>;
      List<dynamic> users = body["users"];
      print(body);
      return users
          .where((element) => element["name"].toString().startsWith("P-"))
          .map((e) =>
              Project(e["id"], e["name"], e["balance"], e["updated"] ?? ""))
          .toList();
    } else {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      initValues();
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> projectsView = [];
    if (projects == null || projects!.isEmpty) {
      projectsView.add(Center(
        child: Text("Keine Transaktionen vorhanden"),
      ));
    } else {
      for (Project project in projects!) {
        projectsView.add(ListTile(
          onTap: () async {
            print(username);
            if (user == null) return;
            await Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => StrichlisteAdd(
                    users: [], userId: user!["id"], recipientId: project.id)));
            _refreshController.requestRefresh();
          },
          leading: Text(
            "${(project.balance / 100).toStringAsFixed(2)}€",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: project.balance < 0 ? Colors.red : Colors.green),
          ),
          title: Text(project.name),
          trailing: Text(project.updated),
        ));
        projectsView.add(Divider());
      }
    }
    return SmartRefresher(
      enablePullDown: true,
      controller: _refreshController,
      onRefresh: update,
      child: ListView(
        children: projectsView,
      ),
    );
  }
}
