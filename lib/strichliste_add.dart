import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:openlabflutter/strichliste.dart';
import 'package:http/http.dart' as http;

List<int> buttonRanges = [50, 100, 200, 500, 1000, 1500, 2000];

class StrichlisteAdd extends StatefulWidget {
  List<User>? users;
  int userId;

  StrichlisteAdd({required this.users, required this.userId});

  @override
  _StrichlisteAddState createState() => _StrichlisteAddState();
}

class _StrichlisteAddState extends State<StrichlisteAdd> {
  TextEditingController amountController = TextEditingController();
  String comment = "";
  User? reciepient;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    amountController.text = "0.00 €";
  }

  void changeAmount(String amount) {
    print(amountController.text.replaceAllMapped(
      RegExp(r"[€\.,]"),
      (match) => "",
    ));

    amountController.text = ((int.parse(amountController.text.replaceAllMapped(
                      RegExp(r"[€\.,]"),
                      (match) => "",
                    )) +
                    int.parse(amount)) /
                100)
            .toStringAsFixed(2) +
        " €";
  }

  Future<void> sendMoney() async {
    var uri = Uri.parse(strichliste + "/user/${widget.userId}/transaction");
    var amount = int.parse(amountController.text.replaceAllMapped(
      RegExp(r"[€\.,]"),
      (match) => "",
    ));
    var body = {
      "amount": amount,
      "quantity": 1,
      "comment": comment,
    };
    if (reciepient != null) {
      body["recipientId"] = reciepient!.id;
      body["amount"] = "-${body["amount"]}";
    }
    print(body);
    var result = await http.post(uri,
        headers: {"Content-Type": "application/json"}, body: jsonEncode(body));
    if (result.statusCode == 200) {
      print(result.body);
      var body = jsonDecode(result.body) as Map<String, dynamic>;
      int transactionId = body["transaction"]["id"];
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.body),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Geld senden")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Form(
            child: ListView(
              children: [
                Autocomplete<String>(
                  fieldViewBuilder: (context, textEditingController, focusNode,
                      onFieldSubmitted) {
                    return TextFormField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        onChanged: (value) {
                          setState(() {
                            reciepient = widget.users!
                                .where(
                                  (element) => element.name
                                      .toLowerCase()
                                      .contains(value.toLowerCase()),
                                )
                                .firstOrNull;
                          });
                        },
                        decoration: InputDecoration(
                            hintText: "Empfänger",
                            border: OutlineInputBorder()));
                  },
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.isEmpty || widget.users == null) {
                      return widget.users!.map((e) => e.name);
                    } else {
                      return widget.users!
                          .where(
                            (element) => element.name
                                .toLowerCase()
                                .contains(textEditingValue.text.toLowerCase()),
                          )
                          .map((e) => e.name);
                    }
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Wrap(
                    children: [
                      for (int i in buttonRanges)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            onPressed: () => changeAmount(i.toString()),
                            child: Text(
                              "+ ${(i / 100).toStringAsFixed(2)}€",
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green),
                          ),
                        )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove),
                        onPressed: () => changeAmount((-100).toString()),
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: amountController,
                          decoration: InputDecoration(
                              hintText: "Amount", border: OutlineInputBorder()),
                          inputFormatters: [
                            CurrencyInputFormatter(
                                thousandSeparator: ThousandSeparator.Period,
                                mantissaLength: 2,
                                trailingSymbol: "€")
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () => changeAmount((100).toString()),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Wrap(
                    children: [
                      for (int i in buttonRanges)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            onPressed: () => changeAmount((-i).toString()),
                            child: Text(
                              "- ${(i / 100).toStringAsFixed(2)}€",
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                          ),
                        )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    decoration: InputDecoration(
                        hintText: "Kommentar", border: OutlineInputBorder()),
                    onChanged: (value) {},
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: sendMoney,
                    child: Text("Katsching!", style: TextStyle(fontSize: 30)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
