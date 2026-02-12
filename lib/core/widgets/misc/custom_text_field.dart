import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final bool obscureText;
  final Function(String)? onChange;

  const CustomTextField({
    super.key,
    required this.hintText,
    required this.controller,
    required this.obscureText,
    this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(labelText: hintText),
      controller: controller,
      obscureText: obscureText,
      onChanged: onChange,
    );
  }
}
