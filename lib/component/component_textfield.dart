import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String? label;
  final Widget? icon;
  final bool? isPassword;
  final TextInputType? textInputType;
  final TextEditingController? textEditingController;

  const CustomTextField({
    Key? key,
    this.label,
    this.icon,
    this.isPassword = false,
    this.textInputType,
    @required this.textEditingController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      child: TextField(
        keyboardType: textInputType,
        controller: textEditingController,
        style: const TextStyle(
            color: Color(0xFF234253),
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
            letterSpacing: 1),
        obscureText: isPassword ?? false,
        decoration: InputDecoration(
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF7E8188), width: 1.0),
              borderRadius: BorderRadius.circular(5),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF7E8188), width: 1.0),
              borderRadius: BorderRadius.circular(5),
            ),
            labelText: label,
            labelStyle: const TextStyle(
                color: Color(0xFF7E8188), fontWeight: FontWeight.bold),
            suffixIcon: icon),
      ),
    );
  }
}
