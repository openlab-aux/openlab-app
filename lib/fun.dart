import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:openlabflutter/platform_helper.dart';
import 'package:http/http.dart' as http;
import 'package:dart_ping/dart_ping.dart'; // Retained for pinging

import 'dart:developer' as developer; // Import for logging

class FunWidget extends StatefulWidget {
  const FunWidget({super.key}); // Added key parameter

  @override
  // Linter warning: "Invalid use of a private type in a public API."
  // This is a common and accepted pattern in Flutter for StatefulWidget's createState method.
  _FunWidgetState createState() => _FunWidgetState();
}

class _FunWidgetState extends State<FunWidget> {
  String flipdotText = "";
  final storage = FlutterSecureStorage();

  TextEditingController flipdotTextController = TextEditingController();

  // HTTP Request form controllers
  TextEditingController urlController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController requestBodyController = TextEditingController();

  String selectedHttpMethod = 'GET';
  bool useBasicAuth = false;
  String httpResponse = '';
  bool isLoading = false;

  // Network Tools controllers
  TextEditingController pingHostController = TextEditingController();
  String pingResult = '';
  bool isPinging = false;
  bool isScanning = false;

  List<ActiveHost> arpResults = [];

  final List<String> httpMethods = ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'];

  // Use _mounted internal flag for async safety, similar to the `mounted` getter
  // but explicitly managed for situations where `mounted` might be checked too late.
  // The `mounted` getter is preferred where available.
  // We'll rely on the framework's `mounted` getter for widget State lifecycle.
  // For BuildContext across async gaps, the `if (!mounted) return;` is sufficient.

  @override
  void initState() {
    super.initState();
    // No explicit _mounted = true needed here as `mounted` is true in initState
  }

  @override
  void dispose() {
    flipdotTextController.dispose();
    urlController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    requestBodyController.dispose();
    pingHostController.dispose();
    super.dispose();
  }

  void sendFlipdotText() async {
    if (flipdotText.isEmpty) {
      developer.log("Kein Text zum Senden");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://flipdot.openlab-augsburg.de//api/v2/queue/add'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'text': flipdotText},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final id = jsonResponse['id'];
        final text = jsonResponse['text'];

        developer.log(
          "Erfolg! Zur Warteschlange hinzugefügt mit ID: $id, Text: '$text'",
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Text zur Flipdot-Warteschlange hinzugefügt (ID: $id)",
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );

        setState(() {
          flipdotText = "";
          flipdotTextController.clear();
        });
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

        developer.log("Fehler beim Senden an Flipdot: $errorMessage");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Senden fehlgeschlagen: $errorMessage"),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      developer.log("Netzwerkfehler beim Senden an Flipdot: $e");

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Netzwerkfehler: Flipdot-Server nicht erreichbar"),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> getQueue() async {
    try {
      final response = await http.get(
        Uri.parse('https://flipdot.openlab-augsburg.de/api/v2/queue'),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final queue = jsonResponse['queue'];
        final length = jsonResponse['length'];

        developer.log("Aktuelle Warteschlangenlänge: $length");
        for (var item in queue) {
          developer.log("ID: ${item['id']}, Text: '${item['text']}'");
        }

        _showQueueBottomSheet(queue, length);
      } else {
        developer.log(
          "Fehler beim Abrufen der Warteschlange: ${response.statusCode}",
        );
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
    } catch (e) {
      developer.log("Netzwerkfehler beim Abrufen der Warteschlange: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Netzwerkfehler: Server nicht erreichbar"),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> sendHttpRequest() async {
    if (urlController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Bitte geben Sie eine URL ein"),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
      httpResponse = '';
    });

    try {
      Uri uri = Uri.parse(urlController.text);
      Map<String, String> headers = {'Content-Type': 'application/json'};

      // Add basic auth if enabled
      if (useBasicAuth && usernameController.text.isNotEmpty) {
        String credentials = base64Encode(
          utf8.encode('${usernameController.text}:${passwordController.text}'),
        );
        headers['Authorization'] = 'Basic $credentials';
      }

      http.Response response;

      switch (selectedHttpMethod) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: headers,
            body: requestBodyController.text.isNotEmpty
                ? requestBodyController.text
                : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: headers,
            body: requestBodyController.text.isNotEmpty
                ? requestBodyController.text
                : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers);
          break;
        case 'PATCH':
          response = await http.patch(
            uri,
            headers: headers,
            body: requestBodyController.text.isNotEmpty
                ? requestBodyController.text
                : null,
          );
          break;
        default:
          response = await http.get(uri, headers: headers);
      }

      if (!mounted) return;

      setState(() {
        httpResponse =
            'Status: ${response.statusCode}\n\n'
            'Headers:\n${response.headers.entries.map((e) => '${e.key}: ${e.value}').join('\n')}\n\n'
            'Body:\n${response.body}';
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("HTTP-Anfrage erfolgreich (${response.statusCode})"),
          backgroundColor: response.statusCode < 400
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        httpResponse = 'Fehler: $e';
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("HTTP-Anfrage fehlgeschlagen: $e"),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> pingHost() async {
    if (pingHostController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Bitte geben Sie eine Host-Adresse ein"),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      isPinging = true;
      pingResult = '';
    });

    try {
      String host = pingHostController.text.trim();

      // Perform ping with 4 packets using dart_ping
      final ping = Ping(host, count: 4);

      String result = 'Ping zu $host:\n\n';

      await for (final response in ping.stream) {
        if (!mounted) return;

        if (response.response != null) {
          // Access seq from PingResponse object
          result +=
              'Antwort von ${response.response!.ip}: '
              'Zeit=${response.response!.time?.inMilliseconds ?? 0}ms '
              'TTL=${response.response!.ttl ?? 0} '
              'Seq=${response.response!.seq}\n'; // Corrected: Access seq via response.response
        } else if (response.error != null) {
          // Using toString() for robustness, as 'type' or 'name' might vary by dart_ping version.
          result += 'Fehler für Paket: ${response.error.toString()}\n';
        } else {
          // For timeout, PingData itself doesn't have seq, so just report timeout
          result +=
              'Timeout für $host\n'; // Corrected: No ip on PingData for timeouts
        }
      }

      if (!mounted) return;

      setState(() {
        pingResult = result;
        isPinging = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Ping abgeschlossen"),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        pingResult = 'Ping-Fehler: $e';
        isPinging = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Ping fehlgeschlagen: $e"),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> scanLocalNetwork() async {
    setState(() {
      isScanning = true;
      arpResults.clear();
    });
    List<ActiveHost> activeHosts = await getPlatformHelper().scanLocalNetwork(
      context,
    );

    setState(() {
      isScanning = false;
      arpResults = activeHosts;
    });
  }

  void _showQueueBottomSheet(List queue, int length) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.queue_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
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
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: queue.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant.withOpacity(0.6),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Warteschlange ist leer",
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          Text(
                            "Keine Nachrichten zum Anzeigen",
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: queue.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = queue[index];
                        return Card(
                          elevation: 0,
                          color: Theme.of(
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
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "#${item['id']}",
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['text'],
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Position ${index + 1} von $length",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
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
    return SingleChildScrollView(
      child: Form(
        child: Column(
          children: [
            ExpansionTile(
              title: Text(
                "Flipdot",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 8.0),
                  child: TextFormField(
                    controller: flipdotTextController,
                    maxLines: 3,
                    maxLength: 512,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      label: Text("Flipdot Text"),
                      helperText: "Maximal 512 Zeichen",
                    ),
                    onChanged: (value) {
                      setState(() {
                        // Use setState directly as we are within build context
                        flipdotText = value;
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FilledButton(
                    onPressed: flipdotText.isNotEmpty
                        ? () => sendFlipdotText()
                        : null,
                    child: const Text("An Flipdot-Warteschlange senden"),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: OutlinedButton.icon(
                    onPressed: () => getQueue(),
                    icon: const Icon(Icons.queue_outlined),
                    label: const Text("Flipdot-Warteschlange anzeigen"),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: FilledButton.tonal(
                onPressed: () => getPlatformHelper().dummrumleuchte(),
                child: const Text("Dummrumleuchte aktivieren"),
              ),
            ),
            ExpansionTile(
              title: Text(
                "HTTP Anfragen",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 8.0),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedHttpMethod,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          label: Text("HTTP Methode"),
                        ),
                        items: httpMethods.map((String method) {
                          return DropdownMenuItem<String>(
                            value: method,
                            child: Text(method),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          if (value != null) {
                            setState(() {
                              selectedHttpMethod = value;
                            });
                          }
                        },
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: urlController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          label: Text("URL"),
                          hintText: "https://example.com/api",
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
                  child: CheckboxListTile(
                    title: Text("Basic Authentication verwenden"),
                    value: useBasicAuth,
                    onChanged: (bool? value) {
                      setState(() {
                        useBasicAuth = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                if (useBasicAuth) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: usernameController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              label: Text("Benutzername"),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              label: Text("Passwort"),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (selectedHttpMethod == 'POST' ||
                    selectedHttpMethod == 'PUT' ||
                    selectedHttpMethod == 'PATCH') ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
                    child: TextFormField(
                      controller: requestBodyController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        label: Text("Request Body (JSON)"),
                        hintText: '{"key": "value"}',
                      ),
                    ),
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FilledButton.icon(
                    onPressed: isLoading || urlController.text.isEmpty
                        ? null
                        : () => sendHttpRequest(),
                    icon: isLoading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.send),
                    label: Text(
                      isLoading ? "Wird gesendet..." : "Anfrage senden",
                    ),
                  ),
                ),
                if (httpResponse.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.http, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  "Antwort",
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                Spacer(),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      httpResponse = '';
                                    });
                                  },
                                  icon: Icon(Icons.clear, size: 20),
                                ),
                              ],
                            ),
                            Divider(),
                            Container(
                              width: double.infinity,
                              height: 200,
                              child: SingleChildScrollView(
                                child: SelectableText(
                                  httpResponse,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            ExpansionTile(
              title: Text(
                "Netzwerk-Tools",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              children: [
                // Ping Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Ping",
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: pingHostController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          label: Text("Host/IP-Adresse"),
                          hintText: "google.com oder 192.168.1.1",
                        ),
                        // Added onChanged to trigger rebuild and enable button
                        onChanged: (value) {
                          setState(() {
                            // No specific variable update needed here, just rebuild to enable/disable button
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FilledButton.icon(
                    onPressed: isPinging || pingHostController.text.isEmpty
                        ? null
                        : () => pingHost(),
                    icon: isPinging
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.network_ping),
                    label: Text(isPinging ? "Pinge..." : "Ping starten"),
                  ),
                ),
                if (pingResult.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.network_ping, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  "Ping-Ergebnis",
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      pingResult = '';
                                    });
                                  },
                                  icon: const Icon(Icons.clear, size: 20),
                                ),
                              ],
                            ),
                            const Divider(),
                            SizedBox(
                              // Removed `constraints` here
                              width: double.infinity,
                              height: 150,
                              child: SingleChildScrollView(
                                child: SelectableText(
                                  pingResult,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                // Network Scan Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Lokales Netzwerk scannen",
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Scannt das lokale Netzwerk nach aktiven Geräten",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FilledButton.icon(
                    onPressed: isScanning ? null : () => scanLocalNetwork(),
                    icon: isScanning
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_find),
                    label: Text(
                      isScanning ? "Scanne Netzwerk..." : "Netzwerk scannen",
                    ),
                  ),
                ),
                if (arpResults.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.devices, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  "Gefundene Geräte (${arpResults.length})",
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      arpResults.clear();
                                    });
                                  },
                                  icon: const Icon(Icons.clear, size: 20),
                                ),
                              ],
                            ),
                            const Divider(),
                            // Corrected: Use ConstrainedBox to apply constraints to SizedBox
                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxHeight: 200,
                              ), // Added const
                              child: SizedBox(
                                width: double.infinity,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: arpResults.length,
                                  itemBuilder: (context, index) {
                                    final host = arpResults[index];
                                    return ListTile(
                                      leading: const Icon(
                                        Icons.laptop,
                                      ), // Or a more generic device icon
                                      title: Text(host.address),
                                      subtitle: Text(
                                        host.macAddress ?? "MAC nicht gefunden",
                                      ),
                                      dense: true,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
