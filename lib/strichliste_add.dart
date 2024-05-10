import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:openlabflutter/strichliste.dart';
import 'package:http/http.dart' as http;

List<int> buttonRanges = [50, 100, 200, 500, 1000, 1500, 2000];

enum StrichlisteAddType { Send, Topup, Buy, Project }

class StrichlisteAdd extends StatefulWidget {
  List<User>? users;
  int userId;
  int? recipientId;
  StrichlisteAddType type;

  StrichlisteAdd(
      {super.key,
      required this.users,
      required this.userId,
      this.recipientId,
      required this.type});

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
    amountController.text = "";
    setState(() {
      reciepient = widget.users!
          .where(
            (element) => element.id == widget.recipientId,
          )
          .firstOrNull;
    });
  }

  void changeAmount(String amount) {
    if (amountController.text.isEmpty) {
      amountController.text = (int.parse(amount) / 100).toString();
      return;
    }
    if ((double.parse(amountController.text.replaceAll(",", "")) * 100) +
            int.parse(amount) <
        0) return;
    amountController.text =
        (((double.parse(amountController.text.replaceAll(",", "")) * 100) +
                    int.parse(amount)) /
                100)
            .toStringAsFixed(2);
  }

  Future<void> sendMoney() async {
    var uri = Uri.parse("$strichliste/user/${widget.userId}/transaction");
    int amount = (double.parse(amountController.text.replaceAll(",", "")) * 100)
        .ceil()
        .toInt();
    var body = {
      "amount": widget.type == StrichlisteAddType.Topup ? amount : -amount,
      "quantity": 1,
      "comment": comment,
    };
    if (widget.recipientId != null) {
      body["recipientId"] = widget.recipientId.toString();
    } else if (reciepient != null)
      body["recipientId"] = reciepient!.id.toString();
    var result = await http.post(uri,
        headers: {"Content-Type": "application/json"}, body: jsonEncode(body));
    if (result.statusCode == 200) {
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
    var header = "Spenden";
    switch (widget.type) {
      case StrichlisteAddType.Send:
        header = "Geld senden";
        break;
      case StrichlisteAddType.Project:
        header = "Projekt unterstützen";
        break;
      case StrichlisteAddType.Topup:
        header = "Geld aufladen";
        break;
      case StrichlisteAddType.Buy:
        header = "Spenden";
        break;
      default:
        header = "Spenden";
        break;
    }
    return Scaffold(
      appBar: AppBar(title: Text(header)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Form(
            child: ListView(
              children: [
                if (widget.type == StrichlisteAddType.Send)
                  Autocomplete<String>(
                    fieldViewBuilder: (context, textEditingController,
                        focusNode, onFieldSubmitted) {
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
                          decoration: const InputDecoration(
                              hintText: "Empfänger",
                              border: OutlineInputBorder()));
                    },
                    optionsBuilder: (textEditingValue) {
                      if (textEditingValue.text.isEmpty ||
                          widget.users == null) {
                        return widget.users!.map((e) => e.name);
                      } else {
                        return widget.users!
                            .where(
                              (element) => element.name.toLowerCase().contains(
                                  textEditingValue.text.toLowerCase()),
                            )
                            .map((e) => e.name);
                      }
                    },
                  ),
                if (widget.type == StrichlisteAddType.Topup)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Wrap(
                      children: [
                        for (int i in buttonRanges)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton(
                              onPressed: () => changeAmount(i.toString()),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green),
                              child: Text(
                                "+ ${(i / 100).toStringAsFixed(2)}€",
                                style: const TextStyle(color: Colors.white),
                              ),
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
                        icon: const Icon(Icons.remove),
                        onPressed: () => changeAmount((-100).toString()),
                      ),
                      Expanded(
                        child: TextFormField(
                          keyboardType: const TextInputType.numberWithOptions(
                              signed: true),
                          controller: amountController,
                          decoration: const InputDecoration(
                              hintText: "Amount",
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.euro)),
                          onChanged: (value) {
                            if (double.parse(value.replaceAll(",", "")) < 0) {
                              amountController.value == "0.00";
                            }
                            amountController.text =
                                amountController.text.replaceAll("-", "");
                          },
                          inputFormatters: [
                            CurrencyInputFormatter(
                                thousandSeparator: ThousandSeparator.Comma,
                                mantissaLength: 2,
                                trailingSymbol: "")
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => changeAmount((100).toString()),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    decoration: const InputDecoration(
                        hintText: "Kommentar", border: OutlineInputBorder()),
                    onChanged: (value) {},
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: sendMoney,
                    child: const Text("Katsching!",
                        style: TextStyle(fontSize: 30)),
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
