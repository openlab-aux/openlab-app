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

  RefreshController _refreshController = RefreshController(
    initialRefresh: true,
  );

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
          .map(
            (e) =>
                Project(e["id"], e["name"], e["balance"], e["updated"] ?? ""),
          )
          .toList();
    } else {
      return null;
    }
  }

  Widget _buildProjectCard(Project project) {
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
        onTap: () async {
          print(username);
          if (user != null) {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (context) => StrichlisteAdd(
                      users: [],
                      userId: user!["id"],
                      recipientId: project.id,
                      type: StrichlisteAddType.Project,
                    ),
              ),
            );
            _refreshController.requestRefresh();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Bitte hinterlege erst deinen Usernamen in den Einstellungen",
                ),
                backgroundColor: Theme.of(context).colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // Balance Container
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color:
                      project.balance < 0
                          ? Theme.of(context).colorScheme.errorContainer
                          : Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${(project.balance / 100).toStringAsFixed(2)}€",
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color:
                        project.balance < 0
                            ? Theme.of(context).colorScheme.onErrorContainer
                            : Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              SizedBox(width: 16),
              // Project details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (project.updated.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        project.updated,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Arrow icon
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 16),
            Text(
              "Keine Projekte vorhanden",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
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
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: SmartRefresher(
          enablePullDown: true,
          controller: _refreshController,
          onRefresh: update,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child:
                projects == null || projects!.isEmpty
                    ? Center(child: _buildEmptyState())
                    : ListView.separated(
                      itemCount: projects!.length,
                      separatorBuilder:
                          (context, index) => SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildProjectCard(projects![index]);
                      },
                    ),
          ),
        ),
      ),
    );
  }
}
