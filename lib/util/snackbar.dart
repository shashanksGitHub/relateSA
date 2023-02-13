import 'package:flutter/material.dart';

class CustomSnackbar {

  static showSnackBar({String? text, BuildContext? context}) {
    ScaffoldMessenger.of(context!).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text!),
      duration: Duration(seconds: 3),
    ));
  }
}
