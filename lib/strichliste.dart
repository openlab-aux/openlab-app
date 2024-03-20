import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ndef/ndef.dart';
import 'package:http/http.dart' as http;

class Article {
  int articleId;
  int amount;
  String name;

  Article(this.articleId, this.amount, this.name);
}

class Strichliste extends StatefulWidget {
  const Strichliste({super.key});

  @override
  State<Strichliste> createState() => _StrichlisteState();
}

class _StrichlisteState extends State<Strichliste> {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  String username = "";
  String userId = "";
  static const String strichliste = "http://strichliste.lab/api";
  int lastTransaction = -1;

  Future<int> getUserId() async {
    if (username.isEmpty) return -1;
    var uri = Uri.parse(strichliste + "/user/search");
    uri = uri.replace(queryParameters: {"query": username, "limit": "1"});
    var result = await http.get(uri);
    if (result.statusCode == 200) {
      var body = jsonDecode(result.body) as Map<String, dynamic>;
      return body["users"].first["id"];
    } else {
      return -1;
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

  Future<void> addTransaction(Article? article, int userId) async {
    if (article == null || userId == -1) return;
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
      print("NFC not available");
    } // timeout only works on Android, while the latter two messages are only for iOS
    var tag = await FlutterNfcKit.poll(
        timeout: Duration(days: 9),
        iosMultipleTagMessage: "Multiple tags found!",
        iosAlertMessage: "Scan your tag");
    print(jsonEncode(tag));
    List<NDEFRecord> result = await FlutterNfcKit.readNDEFRecords();
    if (result.length > 0) {
      String payload = String.fromCharCodes(result.first.payload ?? []);
      RegExp validMessage = RegExp(r'(\w+)\:(\d+)');
      Match? match = validMessage.firstMatch(payload);
      if (match == null) return;
      if (match!.group(1) == "enStl") {
        String? barcode = match!.group(2);
        if (barcode == null) return;
        print(barcode);
        int userId = await getUserId();
        print(userId);
        if (userId == -1) return;
        Article? article = await getArticle(barcode);
        if (article == null) return;
        print(article.articleId);
        await addTransaction(article, userId);
      }
    }
  }

  void initValues() async {
    String u = await storage.read(key: "username") ?? "";
    setState(() {
      this.username = u;
    });
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      initValues();
      getUserId();
      readNFC();
    });
  }

  @override
  Widget build(BuildContext context) {
    readNFC();
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Halte dein Smartphone an den passenden NFC Tag um ein Buchung durchzuführen",
              style: TextStyle(
                fontSize: 30,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Icon(
            Icons.nfc,
            size: 200,
          )
        ],
      ),
    );
  }
}
