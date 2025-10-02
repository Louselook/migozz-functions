enum NameFormat { short, firstOnly, initials, full }

String formatDisplayName(String? text, {NameFormat format = NameFormat.short}) {
  if (text == null || text.isEmpty) return "John Doe";

  final parts = text.split(" ");
  if (parts.isEmpty) return text;

  switch (format) {
    case NameFormat.short:
      return parts.length > 1 ? "${parts[0]} ${parts[1][0]}." : parts[0]; // Agarra el primer numero y el segundo se toma la primera letra en mayuscula

    case NameFormat.firstOnly: // Agarra solo el primer nombre
      return parts[0];

    case NameFormat.initials:
      return parts.map((p) => "${p[0].toUpperCase()}.").join(""); // Agarra solo las iniciales

    case NameFormat.full: // Todo el nombre
      return text;
  }
}
