import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ndef/ndef.dart';
import 'package:http/http.dart' as http;
import 'package:openlabflutter/scanner.dart';
import 'package:openlabflutter/strichliste_add.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

const String strichliste = "http://strichliste.lab/api";

class Article {
  int articleId;
  int amount;
  String name;

  Article(this.articleId, this.amount, this.name);
}

class Transaction {
  int id;
  int amount;
  bool deleted;
  String comment;
  int? sender;
  int? reciepient;
  String created;
  String articleName;
  Transaction(
    this.id,
    this.amount,
    this.deleted,
    this.comment,
    this.created,
    this.articleName,
  );
}

class User {
  int id;
  String name;
  User(this.id, this.name);
}

class Strichliste extends StatefulWidget {
  const Strichliste({super.key});

  @override
  State<Strichliste> createState() => _StrichlisteState();
}

class _StrichlisteState extends State<Strichliste> {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  String username = "";
  int lastTransaction = -1;
  Map<String, dynamic>? user;
  List<Transaction>? transactions;
  RefreshController _refreshController = RefreshController(
    initialRefresh: true,
  );
  bool nfcAvailable = true;
  bool _mounted = true;

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> update() async {
    print("updating");

    Map<String, dynamic>? user = await getUser();
    print(user);
    if (_mounted) {
      setState(() {
        this.user = user;
      });
    }
    if (user != null) {
      List<Transaction>? transactions = await getTransactions(user!["id"]);
      if (transactions != null) {
        transactions.sort((a, b) {
          return DateTime.parse(a.created).compareTo(DateTime.parse(b.created));
        });
        transactions = transactions.reversed.toList();
      }
      if (_mounted) {
        setState(() {
          this.transactions = transactions;
        });
      }
    }
    _refreshController.refreshCompleted();
    readNFC();
  }

  Future<Map<String, dynamic>?> getUser() async {
    print(username);
    if (username.isEmpty) return null;
    var uri = Uri.parse("$strichliste/user/search");
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

  Future<Article?> getArticle(String barcode) async {
    if (barcode.isEmpty) return null;
    var uri = Uri.parse("$strichliste/article/search");
    uri = uri.replace(queryParameters: {"barcode": barcode, "limit": "1"});
    var result = await http.get(uri);
    if (result.statusCode == 200) {
      var body = jsonDecode(result.body) as Map<String, dynamic>;
      dynamic article = body["articles"].first;
      return Article(article["id"], article["amount"], article["name"]);
    } else {
      return null;
    }
  }

  Future<List<User>?> getUsers() async {
    print("Get user");
    var uri = Uri.parse("$strichliste/user");
    var result = await http.get(uri);
    if (result.statusCode == 200) {
      var body = jsonDecode(result.body) as Map<String, dynamic>;
      List<dynamic> users = body["users"];
      print(body);
      return users
          .map((e) => User(e["id"], e["name"]))
          .where((element) => !element.name.toString().startsWith("P-"))
          .toList();
    } else {
      return null;
    }
  }

  Future<List<Transaction>?> getTransactions(int userId) async {
    var uri = Uri.parse("$strichliste/user/${userId}/transaction");
    var result = await http.get(uri);
    if (result.statusCode == 200) {
      var body = jsonDecode(result.body) as Map<String, dynamic>;
      List<dynamic> transactions = body["transactions"];
      print("transaction body ${body}");
      return transactions
          .map(
            (e) => Transaction(
              e["id"],
              e["amount"],
              e["deleted"] ?? false,
              e["comment"] ?? "",
              e["created"],
              e.containsKey("article") &&
                      e["article"] != null &&
                      e["article"].containsKey("name")
                  ? e["article"]["name"]
                  : "",
            ),
          )
          .toList();
    } else {
      return null;
    }
  }

  Future<void> addMoney(int amount, int userId) async {
    var uri = Uri.parse("$strichliste/user/${userId}/transaction");
    var body = {"amount": amount};
    var result = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
    if (result.statusCode == 200) {
      Navigator.of(context).pop();
    } else {
      if (_mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.body),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> addTransaction(Article? article, int userId) async {
    if (article == null || userId == -1) return;
    print("Addding transaction!!");
    var uri = Uri.parse("$strichliste/user/${userId}/transaction");
    var result = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "articleId": article.articleId,
        "amount": -article.amount,
        "quantity": 1,
      }),
    );
    if (result.statusCode == 200) {
      print(result.body);
      var body = jsonDecode(result.body) as Map<String, dynamic>;
      int transactionId = body["transaction"]["id"];
      if (_mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Du hast ${article.name} für ${article.amount / 100}€ gekauft",
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: "Rückgängig",
              textColor: Theme.of(context).colorScheme.onPrimary,
              onPressed: () {
                undoTransaction(transactionId, userId);
              },
            ),
          ),
        );
      }
    } else {
      print(result.body);
      if (_mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Konnte Artikel nicht hinzufügen"),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> undoTransaction(int transactionId, int userId) async {
    var result = await http.delete(
      Uri.parse("$strichliste/user/${userId}/transaction/${transactionId}"),
      headers: {"Content-Type": "application/json"},
    );
    if (result.statusCode >= 400) {
      if (_mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Rückgängig erfolgreich!"),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> readNFC() async {
    var availability = await FlutterNfcKit.nfcAvailability;

    if (availability != NFCAvailability.available) {
      if (_mounted) {
        setState(() {
          nfcAvailable = false;
        });
      }
      print("NFC not available");
      return;
    } else {
      if (_mounted) {
        setState(() {
          nfcAvailable = true;
        });
      }
    }
    var tag = await FlutterNfcKit.poll(
      timeout: const Duration(days: 9),
      iosMultipleTagMessage: "Multiple tags found!",
      iosAlertMessage: "Scan your tag",
    );
    print(jsonEncode(tag));
    List<NDEFRecord> result = await FlutterNfcKit.readNDEFRecords();
    if (result.length > 0) {
      String payload = String.fromCharCodes(result.first.payload ?? []);
      print("NFC payload: $payload");
      RegExp validMessage = RegExp(r'(\w+)\:(\d+)');
      Match? match = validMessage.firstMatch(payload);
      if (match != null && match!.group(1) == "enStl") {
        String? barcode = match!.group(2);
        if (barcode == null) return;
        print(barcode);
        Map<String, dynamic>? user = await getUser();
        if (user != null) {
          int userId = user!["id"];
          print(userId);
          if (userId == -1) return;
          Article? article = await getArticle(barcode);
          if (article == null) return;
          print(article.articleId);
          await addTransaction(article, userId);
          update();
        } else {
          if (_mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  "Bitte hinterlege erst deinen Usernamen in den Einstellungen",
                ),
                backgroundColor: Theme.of(context).colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
      if (match != null && match!.group(1) == "enSpende") {
        String? cent = match!.group(2);
        if (cent == null) return;
        print(cent);
        Map<String, dynamic>? user = await getUser();
        if (user != null) {
          int userId = user!["id"];
          print(userId);
          if (userId == -1) return;
          await showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text(
                  "Hast du gerade ${(int.parse(cent) / 100).toString()}€ eingezahlt?",
                ),
                actions: [
                  TextButton(
                    child: const Text("Ja"),
                    onPressed: () async {
                      addMoney(int.parse(cent), userId);
                    },
                  ),
                  TextButton(
                    child: const Text("Nein"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
          update();
        } else {
          if (_mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  "Bitte hinterlege erst deinen Usernamen in den Einstellungen",
                ),
                backgroundColor: Theme.of(context).colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } else {
        if (_mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Kein Strichlisten-NFC Tag"),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> scanArticle() async {}

  void initValues() async {
    String u = await storage.read(key: "nickname") ?? "";

    print("username: $u");
    if (_mounted) {
      setState(() {
        this.username = u;
      });
    }
    await update();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      initValues();
      readNFC();
    });
  }

  Widget _buildTransactionCard(Transaction transaction) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color:
                    transaction.amount < 0
                        ? Theme.of(context).colorScheme.errorContainer
                        : Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "${(transaction.amount / 100).toStringAsFixed(2)}€",
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color:
                      transaction.amount < 0
                          ? Theme.of(context).colorScheme.onErrorContainer
                          : Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.articleName.isEmpty
                        ? transaction.comment
                        : transaction.articleName,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  SizedBox(height: 4),
                  Text(
                    transaction.created,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Center(
        child: Card(
          margin: EdgeInsets.all(16),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_outline,
                  size: 64,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
                SizedBox(height: 16),
                Text(
                  "Benutzer konfigurieren",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 8),
                Text(
                  "Bitte konfiguriere erst deinen Benutzer in den Einstellungen",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    List<Widget> transactionsView = [];

    if (transactions == null || transactions!.isEmpty) {
      transactionsView.add(
        Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
                SizedBox(height: 16),
                Text(
                  "Keine Transaktionen",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  "Es sind noch keine Transaktionen vorhanden",
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
      );
    } else {
      for (Transaction transaction in transactions!) {
        transactionsView.add(_buildTransactionCard(transaction));
      }
    }

    return Stack(
      children: [
        // Main content area with proper spacing for cards
        Padding(
          padding: const EdgeInsets.only(top: 100, bottom: 120),
          child: SmartRefresher(
            enablePullDown: true,
            controller: _refreshController,
            onRefresh: update,
            child: ListView(
              padding: EdgeInsets.only(bottom: 16),
              children: transactionsView,
            ),
          ),
        ),

        // NFC Card at top
        if (nfcAvailable)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.nfc,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Halte dein Smartphone an den NFC Tag um eine Buchung durchzuführen",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Balance Card at bottom
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Kontostand: ",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          user!["balance"] >= 0
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "${(user!["balance"] / 100).toString()}€",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color:
                            user!["balance"] >= 0
                                ? Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer
                                : Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Floating Action Buttons
        Positioned(
          bottom: 180,
          right: 20,
          child: FloatingActionButton(
            heroTag: "send",
            child: const Icon(Icons.send),
            onPressed: () async {
              List<User>? users = await getUsers();
              if (user != null) {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (context) => StrichlisteAdd(
                          userId: user!["id"],
                          users: users,
                          type: StrichlisteAddType.Send,
                        ),
                  ),
                );
                _refreshController.requestRefresh();
              } else {
                if (_mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        "Bitte hinterlege erst deinen Usernamen in den Einstellungen",
                      ),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
        ),
        Positioned(
          bottom: 180,
          left: 90,
          child: FloatingActionButton(
            heroTag: "barcodeScan",
            child: const Icon(Icons.qr_code_scanner),
            onPressed: () async {
              List<User>? users = await getUsers();
              print(users);
              if (user != null) {
                BarcodeCapture? capture = await Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (context) => Scanner()));
                if (capture != null &&
                    capture.barcodes.isNotEmpty &&
                    capture.barcodes.first.rawValue != null &&
                    int.tryParse(capture.barcodes.first.rawValue!) != null) {
                  Article? article = await getArticle(
                    capture.barcodes.first.rawValue!,
                  );
                  if (article != null) {
                    await addTransaction(article, user!["id"]);
                    print("After add transaction");
                    _refreshController.requestRefresh();
                  } else {
                    if (_mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("Konnte Artikel nicht finden"),
                          backgroundColor: Theme.of(context).colorScheme.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                } else {
                  if (_mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("Etwas ist leider schief gelaufen"),
                        backgroundColor: Theme.of(context).colorScheme.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              } else {
                if (_mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        "Bitte hinterlege erst deinen Usernamen in den Einstellungen",
                      ),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
        ),
        Positioned(
          bottom: 110,
          right: 20,
          child: FloatingActionButton(
            heroTag: "topUp",
            child: const Icon(Icons.account_balance_wallet),
            onPressed: () async {
              List<User>? users = await getUsers();
              if (user != null) {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (context) => StrichlisteAdd(
                          userId: user!["id"],
                          users: users,
                          type: StrichlisteAddType.Topup,
                        ),
                  ),
                );
                _refreshController.requestRefresh();
              } else {
                if (_mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        "Bitte hinterlege erst deinen Usernamen in den Einstellungen",
                      ),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
        ),
        Positioned(
          bottom: 110,
          left: 20,
          child: FloatingActionButton.extended(
            heroTag: "buy",
            icon: const Icon(Icons.shopping_cart),
            label: const Text("Kaufen"),
            onPressed: () async {
              List<User>? users = await getUsers();
              if (user != null) {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (context) => StrichlisteAdd(
                          userId: user!["id"],
                          users: users,
                          type: StrichlisteAddType.Buy,
                        ),
                  ),
                );
                _refreshController.requestRefresh();
              } else {
                if (_mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        "Bitte hinterlege erst deinen Usernamen in den Einstellungen",
                      ),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
        ),
      ],
    );
  }
}
