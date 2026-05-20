import 'package:flutter/material.dart';

extension BuildContextX on BuildContext {
  void showSnackBar(String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.of(this);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Theme.of(this).colorScheme.error : null,
      ),
    );
  }
}
