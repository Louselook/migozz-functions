enum FormatName { short, firstOnly, initials, full }

String formatDisplayName(String? text, {FormatName format = FormatName.short}) {
  if (text == null || text.isEmpty) return "John Doe";

  final parts = text.split(" ");
  if (parts.isEmpty) return text;

  switch (format) {
    case FormatName.short:
      return parts.length > 1
          ? "${parts[0]} ${parts[1][0].toUpperCase()}"
          : parts[0]; // Agarra el primer numero y el segundo se toma la primera letra en mayuscula

    case FormatName.firstOnly: // Agarra solo el primer nombre
      return parts[0];

    case FormatName.initials:
      return parts
          .map((p) => "${p[0].toUpperCase()}.")
          .join(""); // Agarra solo las iniciales

    case FormatName.full: // Todo el nombre
      return text;
  }
}

// cambio de numeros
String formatNumber(num number) {
  if (number >= 1000000000000) {
    return "${(number / 1000000000000).toStringAsFixed(1)} T";
  } else if (number >= 1000000000) {
    return "${(number / 1000000000).toStringAsFixed(1)} B";
  } else if (number >= 1000000) {
    return "${(number / 1000000).toStringAsFixed(1)} M";
  } else if (number >= 1000) {
    return "${(number / 1000).toStringAsFixed(1)} K";
  } else {
    return number.toString();
  }
}

/// Parsea un valor dinámico (int, double o String con sufijos K, M, B) a int.
int parseFormattedNumber(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.round();
  if (v is String) {
    String str = v.toUpperCase().trim();
    double multiplier = 1.0;

    if (str.contains('M')) {
      multiplier = 1000000.0;
    } else if (str.contains('K')) {
      multiplier = 1000.0;
    } else if (str.contains('B')) {
      multiplier = 1000000000.0;
    } else if (str.contains('T')) {
      multiplier = 1000000000000.0;
    }

    // Remover caracteres no numéricos excepto el punto decimal o coma
    str = str.replaceAll(RegExp(r'[^0-9.,]'), '').replaceAll(',', '.');

    if (multiplier > 1.0) {
      double? val = double.tryParse(str);
      if (val != null) {
        return (val * multiplier).round();
      }
    } else {
      return int.tryParse(str) ?? 0;
    }
  }
  return 0;
}
