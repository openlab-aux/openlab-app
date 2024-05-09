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
  Transaction(this.id, this.amount, this.deleted, this.comment, this.created,
      this.articleName);
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
  RefreshController _refreshController =
      RefreshController(initialRefresh: true);
  bool nfcAvailable = true;

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

  Future<Article?> getArticle(String barcode) async {
    if (barcode.isEmpty) return null;
    var uri = Uri.parse(strichliste + "/article/search");
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
    var uri = Uri.parse(strichliste + "/user");
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
    var uri = Uri.parse(strichliste + "/user/${userId}/transaction");
    var result = await http.get(uri);
    if (result.statusCode == 200) {
      var body = jsonDecode(result.body) as Map<String, dynamic>;
      List<dynamic> transactions = body["transactions"];
      print("transaction body ${body}");
      return transactions
          .map((e) => Transaction(
              e["id"],
              e["amount"],
              e["deleted"] ?? false,
              e["comment"] ?? "",
              e["created"],
              e.containsKey("article") &&
                      e["article"] != null &&
                      e["article"].containsKey("name")
                  ? e["article"]["name"]
                  : ""))
          .toList();
    } else {
      return null;
    }
  }

  Future<void> addTransaction(Article? article, int userId) async {
    if (article == null || userId == -1) return;
    print("Addding transaction!!");
    var uri = Uri.parse(strichliste + "/user/${userId}/transaction");
    var result = await http.post(uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "articleId": article.articleId,
          "amount": -article.amount,
          "quantity": 1
        }));
    if (result.statusCode == 200) {
      print(result.body);
      var body = jsonDecode(result.body) as Map<String, dynamic>;
      int transactionId = body["transaction"]["id"];
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            "Du hast ${article.name} für ${article.amount / 100}€ gekauft"),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: "undo",
          onPressed: () {
            undoTransaction(transactionId, userId);
          },
        ),
      ));
    } else {
      print(result.body);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Konnte Artikel nicht hinzufügen"),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> undoTransaction(int transactionId, int userId) async {
    var result = await http.delete(
      Uri.parse(strichliste + "/user/${userId}/transaction/${transactionId}"),
      headers: {"Content-Type": "application/json"},
    );
    if (result.statusCode >= 400) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Undo successfull!")));
    }
  }

  Future<void> readNFC() async {
    var availability = await FlutterNfcKit.nfcAvailability;

    if (availability != NFCAvailability.available) {
      // oh-no
      setState(() {
        nfcAvailable = false;
      });
      print("NFC not available");
      return;
    } else {
      // timeout only works on Android, while the latter two messages are only for iOS
      setState(() {
        nfcAvailable = true;
      });
    }
    var tag = await FlutterNfcKit.poll(
        timeout: Duration(days: 9),
        iosMultipleTagMessage: "Multiple tags found!",
        iosAlertMessage: "Scan your tag");
    print(jsonEncode(tag));
    List<NDEFRecord> result = await FlutterNfcKit.readNDEFRecords();
    if (result.length > 0) {
      String payload = String.fromCharCodes(result.first.payload ?? []);
      print("NFC payload: " + payload);
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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                "Bitte hinterlege erst deinen Usernamen in den Einstellungen"),
            backgroundColor: Colors.red,
          ));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Kein Strichlisten-NFC Tag"),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> scanArticle() async {}

  void initValues() async {
    String u = await storage.read(key: "nickname") ?? "";

    print("username: " + u);
    setState(() {
      this.username = u;
    });
    await update();
  }

  Future<void> update() async {
    print("updating");

    Map<String, dynamic>? user = await getUser();
    print(user);
    setState(() {
      this.user = user;
    });
    if (user != null) {
      List<Transaction>? transactions = await getTransactions(user!["id"]);
      setState(() {
        this.transactions = transactions;
      });
    }
    _refreshController.refreshCompleted();
    readNFC();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      initValues();
      readNFC();
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> transactionsView = [];
    if (transactions == null || transactions!.isEmpty) {
      transactionsView.add(Center(
        child: Text("Keine Transaktionen vorhanden"),
      ));
    } else {
      for (Transaction transaction in transactions!) {
        transactionsView.add(ListTile(
          leading: Text(
            "${(transaction.amount / 100).toStringAsFixed(2)}€",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: transaction.amount < 0 ? Colors.red : Colors.green),
          ),
          title: Text(transaction.articleName.isEmpty
              ? transaction.comment
              : transaction.articleName),
          trailing: Text(transaction.created),
        ));
      }
    }
    return Stack(children: [
      SmartRefresher(
        enablePullDown: true,
        controller: _refreshController,
        onRefresh: update,
        child: ListView(children: [
          if (nfcAvailable)
            Card(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Halte dein Smartphone an den passenden\nNFC Tag um ein Buchung durchzuführen",
                    textAlign: TextAlign.center,
                  ),
                ),
                Icon(
                  Icons.nfc,
                  size: 20,
                )
              ],
            )),
          for (Widget trans in transactionsView) trans
        ]),
      ),
      Positioned(
        bottom: 20,
        right: 20,
        child: FloatingActionButton(
          heroTag: "add",
          child: Icon(Icons.add),
          onPressed: () async {
            List<User>? users = await getUsers();
            print(users);
            if (user != null) {
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (context) =>
                    StrichlisteAdd(userId: user!["id"], users: users),
              ));
              _refreshController.requestRefresh();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    "Bitte hinterlege erst deinen Usernamen in den Einstellungen"),
                backgroundColor: Colors.red,
              ));
            }
          },
        ),
      ),
      Positioned(
        bottom: 90,
        right: 20,
        child: FloatingActionButton(
          heroTag: "barcodeScan",
          child: Icon(Icons.barcode_reader),
          onPressed: () async {
            List<User>? users = await getUsers();
            print(users);
            if (user != null) {
              BarcodeCapture? capture =
                  await Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => Scanner(),
              ));
              if (capture != null &&
                  capture.barcodes.isNotEmpty &&
                  capture.barcodes.first.rawValue != null &&
                  int.tryParse(capture.barcodes.first.rawValue!) != null) {
                Article? article =
                    await getArticle(capture.barcodes.first.rawValue!);
                if (article != null) {
                  await addTransaction(article, user!["id"]);
                  print("After add transaction");
                  _refreshController.requestRefresh();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Konnte Artikel nicht finden"),
                    backgroundColor: Colors.red,
                  ));
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("Etwas ist leider schief gelaufen"),
                  backgroundColor: Colors.red,
                ));
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    "Bitte hinterlege erst deinen Usernamen in den Einstellungen"),
                backgroundColor: Colors.red,
              ));
            }
          },
        ),
      )
    ]);
  }
}
