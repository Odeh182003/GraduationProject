import 'package:flutter/material.dart';

class MyTextfields extends StatelessWidget {
  final String hintText;
  final bool obscureText;
  final TextEditingController controller;

  const MyTextfields({
    super.key,
    required this.hintText,
    required this.obscureText,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextField(
        obscureText: obscureText,
        controller: controller,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: isDarkMode
              ? Colors.grey[900]!.withOpacity(0.9)
              : Colors.white.withOpacity(0.9),
          hintText: hintText,
          hintStyle: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.grey,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: isDarkMode ? Colors.white54 : Colors.grey,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: isDarkMode ? Colors.greenAccent : Colors.green,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }}