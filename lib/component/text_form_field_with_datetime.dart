import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:speedotrack/globals.dart';

// ignore: must_be_immutable
class CustomTextFormFieldWithDataTime extends StatelessWidget {
  CustomTextFormFieldWithDataTime({
    Key? key,
    this.controller,
    this.enabled = true,
    @required this.onChanged,
  }) : super(key: key);

  TextEditingController? controller;
  bool? enabled;
  Function(String?)? onChanged;

  DateTime _parseInitialDate() {
    if (controller != null && controller!.text.isNotEmpty) {
      try {
        return DateFormat("yyyy-MM-dd").parse(controller!.text);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled ?? true,
      maxLines: 1,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Field can't be empty";
        }
        return null;
      },
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.only(top: 10, bottom: 10, left: 12, right: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5.0),
        ),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
          child: InkWell(
            onTap: () async {
              DateTime initialDate = _parseInitialDate();
              
              final selectedDate = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
                builder: (BuildContext context, Widget? child) {
                  return Theme(
                    data: ThemeData.light().copyWith(
                      useMaterial3: false,
                      primaryColor: Globals.appColor,
                      dialogBackgroundColor: Colors.white,
                      timePickerTheme: TimePickerThemeData(
                        dialHandColor: Globals.appColor,
                      ),
                      textTheme: const TextTheme(),
                      colorScheme: ColorScheme.light(
                        primary: Globals.appColor,
                        onSurface: Colors.black,
                        onBackground: Colors.orange,
                      ),
                    ),
                    child: child!,
                  );
                },
              );

              if (selectedDate != null && controller != null) {
                String formattedDate = DateFormat("yyyy-MM-dd").format(selectedDate);
                controller!.text = formattedDate;
                if (onChanged != null) {
                  onChanged!(formattedDate);
                }
              }
            },
            child: Image.asset(
              'images/calendar.png',
              width: 5,
              height: 5,
            ),
          ),
        ),
      ),
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
      onChanged: onChanged,
    );
  }
}
