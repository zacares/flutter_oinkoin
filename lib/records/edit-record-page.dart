
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:piggybank/categories/categories-tab-page-view.dart';
import 'package:piggybank/helpers/alert-dialog-builder.dart';
import 'package:piggybank/helpers/datetime-utility-functions.dart';
import 'package:piggybank/helpers/records-utility-functions.dart';
import 'package:piggybank/models/category-type.dart';
import 'package:piggybank/models/category.dart';
import 'package:piggybank/models/record.dart';
import 'package:piggybank/premium/splash-screen.dart';
import 'package:piggybank/premium/util-widgets.dart';
import 'package:piggybank/services/database/database-interface.dart';
import 'package:piggybank/services/service-config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './i18n/edit-record-page.i18n.dart';

class EditRecordPage extends StatefulWidget {

  /// EditMovementPage is a page containing forms for the editing of a Movement object.
  /// EditMovementPage can take the movement object to edit as a constructor parameters
  /// or can create a new Movement otherwise.

  Record passedRecord;
  Category passedCategory;
  EditRecordPage({Key key, this.passedRecord, this.passedCategory}) : super(key: key);

  @override
  EditRecordPageState createState() => EditRecordPageState(this.passedRecord, this.passedCategory);
}

class EditRecordPageState extends State<EditRecordPage> {

  DatabaseInterface database = ServiceConfig.database;
  TextEditingController _textEditingController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Record record;

  Record passedRecord;
  Category passedCategory;
  String currency;

  EditRecordPageState(this.passedRecord, this.passedCategory);

  Future<String> getCurrency() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('currency') ?? "€";
  }

  @override
  void initState() {
    super.initState();
    currency = "€";
    if (passedRecord != null) {
      record = passedRecord;
      _textEditingController.text = getCurrencyValueString(record.value.abs());
    } else {
      record = new Record(null, null, passedCategory, DateTime.now());
    }
    getCurrency().then((value) {
      setState(() {
        currency = value;
      });
    });
    _textEditingController.addListener(() {
      var text = _textEditingController.text.toLowerCase();
      final exp = new RegExp(r'[^\d.]');
      String toRepl = text.replaceAll(",", ".");
      toRepl = toRepl.replaceAll(exp, "");
      _textEditingController.value = _textEditingController.value.copyWith(
        text: toRepl,
        selection:
        TextSelection(baseOffset: toRepl.length, extentOffset: toRepl.length),
        composing: TextRange.empty,
      );
    });

  }

  Widget _createAddNoteCard() {
    return Card(
        elevation: 2,
        child: Container(
          padding: const EdgeInsets.only(bottom: 40.0, top: 10, right: 10, left: 10),
          child: TextFormField(
              onChanged: (text) {
                setState(() {
                  record.description = text;
                });
              },
              style: TextStyle(
                  fontSize: 22.0,
                  color: Colors.black
              ),
              initialValue: record.description,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "Add a note",
              )
          ),
        ),
    );
  }

  Widget _createTitleCard() {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 5, 5, 5),
        child: TextFormField(
            onChanged: (text) {
              setState(() {
                record.description = text;
              });
            },
            style: TextStyle(
                fontSize: 22.0,
                color: Colors.black
            ),
            maxLines: 1,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
                floatingLabelBehavior: FloatingLabelBehavior.always,
                contentPadding: EdgeInsets.all(10),
                border: InputBorder.none,
                hintText: record.category.name,
                labelText: "Record title (optional)"
            )
        ),
      ),
    );
  }

  Widget _createCategoryCard() {
    return Card(
      elevation: 2,
      child: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              InkWell(
                onTap: () async {
                  var selectedCategory = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CategoryTabPageView()),
                  );
                  if (selectedCategory != null) {
                    setState(() {
                      record.category = selectedCategory;
                    });
                  }
                },
                child: Row(
                  children: [
                    _createCategoryCirclePreview(40.0),
                    Container(
                      margin: EdgeInsets.fromLTRB(20, 10, 10, 10),
                      child: Text(record.category.name, style: TextStyle(fontSize: 20, color: Colors.blueAccent),),
                    )
                  ],
                ),
              ),
            ],
          )
      ),
    );
  }

  Widget _createCategoryCirclePreview(double size) {
    Category defaultCategory = Category("Missing".i18n, color: Category.colors[0], iconCodePoint: FontAwesomeIcons.question.codePoint);
    Category toRender = (record.category == null) ? defaultCategory : record.category;
    return Container(
        margin: EdgeInsets.all(10),
        child: ClipOval(
            child: Material(
                color: toRender.color, // button color
                child: InkWell(
                  splashColor: toRender.color, // inkwell color
                  child: SizedBox(width: size, height: size,
                    child: Icon(toRender.icon, color: Colors.white, size: size - 20,),
                  ),
                )
            )
        )
    );
  }

  goToPremiumSplashScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PremiumSplashScren()),
    );
  }

  Widget _createDateCard() {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            InkWell(
              onTap: () async {
                DateTime now = DateTime.now();
                DateTime result = await showDatePicker(context: context,
                    initialDate: now,
                    firstDate: DateTime(1970), lastDate: DateTime.now());
                if (result != null) {
                  setState(() {
                    record.dateTime = result;
                  });
                }
              },
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 28, color: Colors.blueAccent,),
                  Container(
                    margin: EdgeInsets.fromLTRB(20, 10, 10, 10),
                    child: Text(getDateStr(record.dateTime), style: TextStyle(fontSize: 20, color: Colors.blueAccent),),
                  )
                ],
              ),
            ),
            Divider(indent: 40, thickness: 2,),
            InkWell(
              child: Row(
                children: [
                  Icon(Icons.repeat, size: 28, color: Colors.black54,),
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.fromLTRB(20, 10, 10, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Repeat", style: TextStyle(fontSize: 20, color: Colors.black54),),
                          getProLabel(labelFontSize: 12.0)
                        ],
                      ),
                    ),
                  )
                ],
              ),
              onTap: goToPremiumSplashScreen,
            ),
          ],
        )
      ),
    );
  }

  Widget _createAmountCard() {
    return Card(
      elevation: 2,
      child: Container(
        child: IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: EdgeInsets.all(10),
                    margin: EdgeInsets.only(left: 20, right: 20),
                    child: Text(currency, style: TextStyle(fontSize: 32), textAlign: TextAlign.left),
                  ),
                ),
                VerticalDivider(endIndent: 20, indent: 20, color: Colors.black),
                Expanded(
                    child: Container(
                      padding: EdgeInsets.all(10),
                      margin: EdgeInsets.only(right: 20),
                      child: TextFormField(
                          controller: _textEditingController,
                          autofocus: record.value == null,
                          onChanged: (text) {
                            var numericValue = double.tryParse(text);
                            if (numericValue != null) {
                              numericValue = double.parse(numericValue.toStringAsFixed(2));
                              numericValue = numericValue.abs();
                              if (record.category.categoryType == CategoryType.expense) {
                                // value is an expenses, needs to be negative
                                numericValue = numericValue * -1;
                              }
                              record.value = numericValue;
                            }
                          },
                          validator: (value) {
                            if (value.isEmpty) {
                              return "Please enter a value";
                            }
                            var numericValue = double.tryParse(value);
                            if (numericValue == null) {
                              return "Please enter a numeric value";
                            }
                            return null;
                          },
                          textAlign: TextAlign.end,
                          style: TextStyle(
                              fontSize: 32.0,
                              color: Colors.black
                          ),
                          keyboardType: TextInputType.numberWithOptions(signed: false, decimal: true),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "0",
                          )
                      ),
                    )
                )
              ],
            )
        )
      ),
    );
  }

  saveRecord() async {
    if (record.id == null) {
      await database.addRecord(record);
    } else {
      await database.updateRecordById(record.id, record);
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  AppBar _getAppBar() {
    return AppBar(
        title: Text('Edit record'.i18n),
        actions: <Widget>[
          Visibility(
              visible: widget.passedRecord != null,
              child: IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Delete'.i18n, onPressed: () async {
                  AlertDialogBuilder deleteDialog = AlertDialogBuilder("Critical action".i18n)
                      .addSubtitle("Do you really want to delete this record?".i18n)
                      .addTrueButtonName("Yes".i18n)
                      .addFalseButtonName("No".i18n);

                  var continueDelete = await showDialog(context: context, builder: (BuildContext context) {
                    return deleteDialog.build(context);
                  });

                  if (continueDelete) {
                      await database.deleteRecordById(record.id);
                      Navigator.pop(context);
                  }
                }
              )
          ),]
    );
  }

  Widget _getForm() {
    return Form(
      key: _formKey,
      child: Container(
        margin: EdgeInsets.all(10),
        child:  Column(
            children: [
              _createAmountCard(),
              _createCategoryCard(),
              _createTitleCard(),
              _createDateCard(),
              _createAddNoteCard()
            ]
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: _getAppBar(),
        resizeToAvoidBottomPadding: false,
        body: SingleChildScrollView(
            child: _getForm()
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            if (_formKey.currentState.validate()) {
              await saveRecord();
            }
          },
          tooltip: 'Add a new record'.i18n,
          child: const Icon(Icons.save),
        ),
      );
  }
}