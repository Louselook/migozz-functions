import 'package:flutter/material.dart';

Future<DateTimeRange?> showWebDateRangePicker(
  BuildContext context, {
  DateTimeRange? initialDateRange,
}) {
  return showDialog<DateTimeRange>(
    context: context,
    builder: (context) {
      return Center(
        child: Container(
          width: 500,
          height: 600,
          constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: Color(0xFF9747FF), // Purple accent like image
                  onPrimary: Colors.white,
                  surface: Color(0xFF1E1E1E),
                  onSurface: Colors.white,
                  secondary: Color(0xFF9747FF),
                ),
                dialogBackgroundColor: const Color(0xFF1E1E1E),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                dividerColor: Colors.transparent,
              ),
              child: DateRangePickerDialog(
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: initialDateRange,
                saveText: 'Guardar',
                helpText: 'Seleccionar periodo',
                fieldStartLabelText: 'Fecha inicio',
                fieldEndLabelText: 'Fecha fin',
                cancelText: 'Cancelar',
                confirmText: 'Guardar',
                initialEntryMode: DatePickerEntryMode.calendar,
              ),
            ),
          ),
        ),
      );
    },
  );
}
