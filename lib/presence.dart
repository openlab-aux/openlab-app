import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:oidc/oidc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:duration_picker/duration_picker.dart';
import 'package:direct_select/direct_select.dart';
import 'package:oidc_core/oidc_core.dart';

class PresenceResponse {
  final Map<String, DateTime> users;

  PresenceResponse({required this.users});

  factory PresenceResponse.fromJson(Map<String, dynamic> json) {
    Map<String, String> users = Map.from(json['users']);
    return PresenceResponse(
      users: users.map((key, value) => MapEntry(key, DateTime.parse(value))),
    );
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

  const ComingResponse({required this.users});

  factory ComingResponse.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> users = Map.from(json['users']);
    return ComingResponse(
      users: users.map(
        (key, value) => MapEntry(
          key,
          Coming(
            type: ComingType.values.byName(value['coming_type']),
            when: DateTime.parse(value['when']),
            edited: DateTime.parse(value['edited']),
          ),
        ),
      ),
    );
  }
}

class Presence extends StatefulWidget {
  OidcUserManager? oidcManager;
  Function getAccessToken;
  Presence({required this.oidcManager, required this.getAccessToken});
  @override
  _PresenceState createState() => _PresenceState();
}

class _PresenceState extends State<Presence> {
  final String apiUrl = "https://openlapp.lab.weltraumpflege.org";
  PresenceResponse? presence;
  ComingResponse? coming;
  String? nickname;
  bool loggedIn = false;
  bool planingToCome = false;
  Duration whenICome = Duration(minutes: 30);
  ComingType comingType = ComingType.Gammeln;
  bool _mounted = true;

  RefreshController _refreshController = RefreshController(
    initialRefresh: true,
  );
  final GlobalKey bottomSheetGlobalKey = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  void refresh() {
    loadPresence();
    loadComing();
    _refreshController.refreshCompleted();
    _refreshController.loadComplete();
  }

  void loadPresence() async {
    try {
      if (widget.oidcManager != null &&
          widget.oidcManager!.currentUser != null &&
          widget.oidcManager!.currentUser!.userInfo.keys.contains(
            "preferred_username",
          )) {
        nickname =
            widget.oidcManager!.currentUser!.userInfo["preferred_username"];
      }
      http.Response response = await http.get(Uri.parse(apiUrl + "/presence"));
      if (response.statusCode == 200) {
        if (_mounted) {
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
        }
      } else {
        print(response.statusCode);
        if (_mounted) {
          _showErrorSnackBar("Error loading presence: ${response.statusCode}");
        }
      }
    } catch (e) {
      print(e);
      if (_mounted) {
        _showErrorSnackBar("Network error: Could not reach server");
      }
    }
  }

  void loadNickName() async {}
  void loadComing() async {
    try {
      http.Response response = await http.get(Uri.parse(apiUrl + "/coming"));
      if (response.statusCode == 200) {
        if (_mounted) {
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
        }
      } else {
        print(response.statusCode);
        if (_mounted) {
          _showErrorSnackBar(
            "Error loading coming data: ${response.statusCode}",
          );
        }
      }
    } catch (e) {
      print(e);
      if (_mounted) {
        _showErrorSnackBar("Network error: Could not reach server");
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void logout() async {
    if (widget.oidcManager != null && widget.oidcManager!.currentUser == null) {
      widget.getAccessToken();
    }
    try {
      http.Response response = await http.delete(
        Uri.parse(apiUrl + "/presence"),
        body: jsonEncode({"nickname": nickname}),
        headers: {
          "Content-Type": "application/json",
          'Access-Control-Allow-Origin': '*',
        },
      );
      if (response.statusCode == 200) {
        loadPresence();
        if (_mounted) {
          _showSuccessSnackBar("Successfully logged out");
        }
      } else {
        print(response);
        if (_mounted) {
          _showErrorSnackBar("Failed to logout");
        }
      }
    } catch (e) {
      print(e);
      if (_mounted) {
        _showErrorSnackBar("Network error during logout");
      }
    }
  }

  void login() async {
    if (widget.oidcManager != null && widget.oidcManager!.currentUser == null) {
      widget.getAccessToken();
    }
    try {
      http.Response response = await http.put(
        Uri.parse(apiUrl + "/presence"),
        body: jsonEncode({"nickname": nickname}),
        headers: {
          "Content-Type": "application/json",
          'Access-Control-Allow-Origin': '*',
        },
      );
      if (response.statusCode == 200) {
        loadPresence();
        if (_mounted) {
          _showSuccessSnackBar("Successfully logged in");
        }
      } else {
        print(response);
        if (_mounted) {
          _showErrorSnackBar("Failed to login");
        }
      }
    } catch (e) {
      print(e);
      if (_mounted) {
        _showErrorSnackBar("Network error during login");
      }
    }
  }

  Future<void> comingBottomSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateSetter) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  children: [
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      margin: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule_outlined,
                            color: Theme.of(context).colorScheme.primary,
                            size: 28,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Wann kommst du?",
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(Icons.close),
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Dreh öfters um Stunden zu selektieren.",
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            SizedBox(height: 24),
                            Card(
                              elevation: 0,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerLow,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline.withOpacity(0.2),
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: DurationPicker(
                                  duration: whenICome,
                                  onChange: (value) {
                                    setStateSetter(() {
                                      whenICome = value;
                                    });
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: 24),
                            Text(
                              "Was möchtest du tun?",
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 16),
                            Card(
                              elevation: 0,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerLow,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline.withOpacity(0.2),
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: DropdownButtonFormField<ComingType>(
                                  value: comingType,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  items:
                                      ComingType.values
                                          .map(
                                            (e) => DropdownMenuItem(
                                              value: e,
                                              child: Text(e.name),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (value) {
                                    setStateSetter(() {
                                      if (value != null) {
                                        comingType = value;
                                      }
                                    });
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text("Speichern"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void i_am_coming() async {
    if (widget.oidcManager != null && widget.oidcManager!.currentUser == null) {
      widget.getAccessToken();
    }
    await comingBottomSheet();

    try {
      DateTime whenTime = (DateTime.now().add(whenICome)).toUtc();
      http.Response response = await http.put(
        Uri.parse(apiUrl + "/coming"),
        body: jsonEncode({
          "nickname": nickname,
          "coming_type": comingType.name,
          "when":
              "${whenTime.day.toString().padLeft(2, "0")}.${whenTime.month.toString().padLeft(2, "0")}.${whenTime.year.toString().padLeft(2, "0")} ${whenTime.hour.toString().padLeft(2, "0")}:${whenTime.minute.toString().padLeft(2, "0")}:${whenTime.second.toString().padLeft(2, "0")}",
        }),
        headers: {
          "Content-Type": "application/json",
          'Access-Control-Allow-Origin': '*',
        },
      );
      if (response.statusCode == 200) {
        loadComing();
        if (_mounted) {
          _showSuccessSnackBar("Coming status updated successfully");
        }
      } else {
        print(response);
        if (_mounted) {
          _showErrorSnackBar("Failed to update coming status");
        }
      }
    } catch (e) {
      print(e);
      if (_mounted) {
        _showErrorSnackBar("Network error updating coming status");
      }
    }
  }

  void not_coming() async {
    if (widget.oidcManager != null && widget.oidcManager!.currentUser == null) {
      widget.getAccessToken();
    }
    try {
      http.Response response = await http.delete(
        Uri.parse(apiUrl + "/coming"),
        body: jsonEncode({"nickname": nickname}),
        headers: {
          "Content-Type": "application/json",
          'Access-Control-Allow-Origin': '*',
        },
      );
      if (response.statusCode == 200) {
        loadComing();
        if (_mounted) {
          _showSuccessSnackBar("Coming status removed");
        }
      } else {
        print(response);
        if (_mounted) {
          _showErrorSnackBar("Failed to remove coming status");
        }
      }
    } catch (e) {
      print(e);
      if (_mounted) {
        _showErrorSnackBar("Network error removing coming status");
      }
    }
  }

  Widget _buildUserCard(
    String name,
    String time, {
    String? type,
    IconData? icon,
  }) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading:
            icon != null
                ? Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                )
                : null,
        title: Text(name, style: Theme.of(context).textTheme.bodyLarge),
        subtitle:
            type != null
                ? Container(
                  margin: EdgeInsets.only(top: 4),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    type,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                )
                : null,
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            time,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onTertiaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget loginButton = Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
        child: FilledButton.icon(
          onPressed: () {
            if (loggedIn) {
              logout();
            } else {
              login();
            }
          },
          icon: Icon(loggedIn ? Icons.logout : Icons.login),
          label: Text(loggedIn ? "Ausloggen" : "Einloggen"),
        ),
      ),
    );

    Widget comingButton = Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
        child: FilledButton.tonal(
          onPressed: () {
            if (planingToCome) {
              not_coming();
            } else {
              i_am_coming();
            }
          },
          child: Text(planingToCome ? "Doch nicht ..." : "Ich komme!"),
        ),
      ),
    );

    if ((presence == null || coming == null) ||
        (presence!.users.isEmpty && coming!.users.isEmpty)) {
      return Stack(
        children: [
          SmartRefresher(
            controller: _refreshController,
            onRefresh: () => refresh(),
            onLoading: () => refresh(),
            enablePullDown: true,
            enablePullUp: true,
            header: WaterDropHeader(),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Leider niemand da :(",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Pull to refresh",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: SizedBox(
              height: 48,
              width: double.infinity,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [loginButton, comingButton],
              ),
            ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        SmartRefresher(
          controller: _refreshController,
          onRefresh: () => refresh(),
          onLoading: () => refresh(),
          enablePullDown: true,
          enablePullUp: true,
          header: WaterDropHeader(),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Text(
                      "Aktuell im Lab",
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                if (presence!.users.isEmpty)
                  Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          "Niemand im Lab",
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  ...presence!.users.entries.map(
                    (entry) => Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: _buildUserCard(
                        entry.key,
                        "${entry.value.toLocal().hour.toString().padLeft(2, "0")}:${entry.value.toLocal().minute.toString().padLeft(2, "0")}",
                        icon: Icons.person,
                      ),
                    ),
                  ),
                SizedBox(height: 32),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Text(
                      "Hat vor zu kommen",
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                if (coming!.users.isEmpty)
                  Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          "Niemand plant zu kommen",
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  ...coming!.users.entries.map(
                    (entry) => Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: _buildUserCard(
                        entry.key,
                        "${entry.value.when.toLocal().hour.toString().padLeft(2, "0")}:${entry.value.when.toLocal().minute.toString().padLeft(2, "0")}",
                        type: entry.value.type.name,
                        icon: Icons.access_time,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: SizedBox(
            height: 48,
            width: double.infinity,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [loginButton, comingButton],
            ),
          ),
        ),
      ],
    );
  }
}
