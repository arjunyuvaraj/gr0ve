import 'package:flutter/material.dart';
import 'package:gr0ve/utilities/context_extensions.dart';

double getLetterSpacing(int fontSize, double percentage) {
  return fontSize * (percentage / 100);
}

void displayMessageToUser(String message, BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        message,
        style: context.text.headlineSmall?.copyWith(letterSpacing: 1),
      ),
    ),
  );
}
