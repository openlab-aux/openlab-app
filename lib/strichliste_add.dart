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

  StrichlisteAdd({
    super.key,
    required this.users,
    required this.userId,
    this.recipientId,
    required this.type,
  });

  @override
  _StrichlisteAddState createState() => _StrichlisteAddState();
}

class _StrichlisteAddState extends State<StrichlisteAdd> {
  TextEditingController amountController = TextEditingController();
  TextEditingController commentController = TextEditingController();
  String comment = "";
  User? reciepient;

  @override
  void initState() {
    super.initState();
    amountController.text = "";
    setState(() {
      reciepient =
          widget.users!
              .where((element) => element.id == widget.recipientId)
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
        0)
      return;
    amountController.text =
        (((double.parse(amountController.text.replaceAll(",", "")) * 100) +
                    int.parse(amount)) /
                100)
            .toStringAsFixed(2);
  }

  Future<void> sendMoney() async {
    var uri = Uri.parse("$strichliste/user/${widget.userId}/transaction");
    int amount =
        (double.parse(amountController.text.replaceAll(",", "")) * 100)
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
    var result = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
    if (result.statusCode == 200) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.body),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildQuickAmountButton(int cents) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => changeAmount(cents.toString()),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            "+ ${(cents / 100).toStringAsFixed(2)}€",
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountInputCard() {
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
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Betrag",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.remove,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () => changeAmount((-100).toString()),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: true,
                    ),
                    controller: amountController,
                    decoration: InputDecoration(
                      hintText: "0,00",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withOpacity(0.5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      suffixIcon: Icon(
                        Icons.euro,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                    onChanged: (value) {
                      if (double.parse(value.replaceAll(",", "")) < 0) {
                        amountController.value == "0.00";
                      }
                      amountController.text = amountController.text.replaceAll(
                        "-",
                        "",
                      );
                    },
                    inputFormatters: [
                      CurrencyInputFormatter(
                        thousandSeparator: ThousandSeparator.Comma,
                        mantissaLength: 2,
                        trailingSymbol: "",
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.add,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () => changeAmount((100).toString()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipientCard() {
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
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Empfänger",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Autocomplete<String>(
              fieldViewBuilder: (
                context,
                textEditingController,
                focusNode,
                onFieldSubmitted,
              ) {
                return TextFormField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  onChanged: (value) {
                    setState(() {
                      reciepient =
                          widget.users!
                              .where(
                                (element) => element.name
                                    .toLowerCase()
                                    .contains(value.toLowerCase()),
                              )
                              .firstOrNull;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Empfänger auswählen",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withOpacity(0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                );
              },
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text.isEmpty || widget.users == null) {
                  return widget.users!.map((e) => e.name);
                } else {
                  return widget.users!
                      .where(
                        (element) => element.name.toLowerCase().contains(
                          textEditingValue.text.toLowerCase(),
                        ),
                      )
                      .map((e) => e.name);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentCard() {
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
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Kommentar (optional)",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: commentController,
              decoration: InputDecoration(
                hintText: "Wofür ist diese Transaktion?",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                prefixIcon: Icon(
                  Icons.comment_outlined,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: (value) {
                setState(() {
                  comment = value;
                });
              },
              maxLines: 3,
              minLines: 1,
            ),
          ],
        ),
      ),
    );
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
      appBar: AppBar(
        title: Text(header),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              // Recipient selection for Send type
              if (widget.type == StrichlisteAddType.Send) ...[
                _buildRecipientCard(),
                SizedBox(height: 16),
              ],

              // Quick amount buttons for Topup
              if (widget.type == StrichlisteAddType.Topup) ...[
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Schnellauswahl",
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (int i in buttonRanges)
                              _buildQuickAmountButton(i),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
              ],

              // Amount input
              _buildAmountInputCard(),
              SizedBox(height: 16),

              // Comment input
              _buildCommentCard(),
              SizedBox(height: 24),

              // Submit button
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: sendMoney,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        "Katsching!",
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
