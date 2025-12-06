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
    return "${(number / 1000000000000).toStringAsFixed(1)}T";
  } else if (number >= 1000000000) {
    return "${(number / 1000000000).toStringAsFixed(1)}B";
  } else if (number >= 1000000) {
    return "${(number / 1000000).toStringAsFixed(1)}M";
  } else if (number >= 1000) {
    return "${(number / 1000).toStringAsFixed(1)}K";
  } else {
    return number.toString();
  }
}
