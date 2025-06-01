import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:udp/udp.dart';
import 'package:http/http.dart' as http;

class FunWidget extends StatefulWidget {
  @override
  _FunWidgetState createState() => _FunWidgetState();
}

class _FunWidgetState extends State<FunWidget> {
  String flipdotText = "";
  final storage = new FlutterSecureStorage();
  TextEditingController flipdotTextController = new TextEditingController();
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _mounted = false;
    flipdotTextController.dispose();
    super.dispose();
  }

  void dummrumleuchte() async {
    try {
      var sender = await UDP.bind(Endpoint.any(port: Port.any));
      var dataLength = await sender.send(
        "blink".codeUnits,
        Endpoint.unicast(
          (await InternetAddress.lookup("NODE-F4C64E.lab")).first,
          port: Port(5000),
        ),
      );
      sender.close();
      print("Gesendet: 'blink' an NODE-F4C64E.lab:5000, $dataLength Bytes");
    } catch (e) {
      print("Fehler beim Senden der UDP-Nachricht: $e");
    }
  }

  void sendFlipdotText() async {
    if (flipdotText.isEmpty) {
      print("Kein Text zum Senden");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://flipdot.openlab-augsburg.de//api/v2/queue/add'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'text': flipdotText},
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final id = jsonResponse['id'];
        final text = jsonResponse['text'];

        print(
          "Erfolg! Zur Warteschlange hinzugefügt mit ID: $id, Text: '$text'",
        );

        if (_mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Text zur Flipdot-Warteschlange hinzugefügt (ID: $id)",
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        if (_mounted) {
          setState(() {
            flipdotText = "";
            flipdotTextController.clear();
          });
        }
      } else {
        String errorMessage;
        switch (response.statusCode) {
          case 400:
            errorMessage = "Ungültige Anfrage – fehlerhaftes Format";
            break;
          case 415:
            errorMessage = "Text zu lang (max. 512 Bytes) oder Anfrage zu groß";
            break;
          case 503:
            errorMessage =
                "Warteschlange ist voll, bitte später erneut versuchen";
            break;
          default:
            errorMessage =
                "Fehler ${response.statusCode}: ${response.reasonPhrase}";
        }

        print("Fehler beim Senden an Flipdot: $errorMessage");

        if (_mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Senden fehlgeschlagen: $errorMessage"),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      print("Netzwerkfehler beim Senden an Flipdot: $e");

      if (_mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Netzwerkfehler: Flipdot-Server nicht erreichbar"),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> getQueue() async {
    try {
      final response = await http.get(
        Uri.parse('https://flipdot.openlab-augsburg.de/api/v2/queue'),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final queue = jsonResponse['queue'];
        final length = jsonResponse['length'];

        print("Aktuelle Warteschlangenlänge: $length");
        for (var item in queue) {
          print("ID: ${item['id']}, Text: '${item['text']}'");
        }

        if (_mounted) {
          _showQueueBottomSheet(queue, length);
        }
      } else {
        print("Fehler beim Abrufen der Warteschlange: ${response.statusCode}");
        if (_mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Fehler beim Abrufen der Warteschlange: ${response.statusCode}",
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      print("Netzwerkfehler beim Abrufen der Warteschlange: $e");
      if (_mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Netzwerkfehler: Server nicht erreichbar"),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showQueueBottomSheet(List queue, int length) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
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
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.queue_outlined,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Flipdot-Warteschlange",
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "$length ${length == 1 ? 'Eintrag' : 'Einträge'} in der Warteschlange",
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
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
                  child:
                      queue.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 64,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                      .withOpacity(0.6),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "Warteschlange ist leer",
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.copyWith(
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  "Keine Nachrichten zum Anzeigen",
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                        .withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ListView.separated(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: queue.length,
                            separatorBuilder:
                                (context, index) => SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = queue[index];
                              return Card(
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
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          "#${item['id']}",
                                          style: Theme.of(
                                            context,
                                          ).textTheme.labelSmall?.copyWith(
                                            color:
                                                Theme.of(context)
                                                    .colorScheme
                                                    .onPrimaryContainer,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['text'],
                                              style:
                                                  Theme.of(
                                                    context,
                                                  ).textTheme.bodyLarge,
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              "Position ${index + 1} von $length",
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall?.copyWith(
                                                color:
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        children: [
          Text("Flipdot", style: Theme.of(context).textTheme.headlineMedium),
          Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 8.0),
            child: TextFormField(
              controller: flipdotTextController,
              maxLines: 3,
              maxLength: 512,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                label: Text("Flipdot Text"),
                helperText: "Maximal 512 Zeichen",
              ),
              onChanged: (value) {
                if (_mounted) {
                  setState(() {
                    flipdotText = value;
                  });
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FilledButton(
              onPressed:
                  flipdotText.isNotEmpty ? () => sendFlipdotText() : null,
              child: Text("An Flipdot-Warteschlange senden"),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: OutlinedButton.icon(
              onPressed: () => getQueue(),
              icon: Icon(Icons.queue_outlined),
              label: Text("Flipdot-Warteschlange anzeigen"),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FilledButton.tonal(
              onPressed: () => dummrumleuchte(),
              child: Text("Dummrumleuchte aktivieren"),
            ),
          ),
        ],
      ),
    );
  }
}
