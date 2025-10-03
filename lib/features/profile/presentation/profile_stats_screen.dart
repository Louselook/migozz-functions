import 'package:flutter/material.dart';

// TODA ESTA VISTA ESTA CON DATOS QUEMADOS

class ProfileStatsScreen extends StatelessWidget {
  const ProfileStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: const Text('My Stats', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // MÉTRICAS ARRIBA
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  // Likes
                  Column(
                    children: [
                      Icon(Icons.favorite, color: Colors.white, size: 28),
                      SizedBox(height: 4),
                      Text("3.1 mill.", style: TextStyle(color: Colors.white)), 
                    ],
                  ),
                  // Comentarios
                  Column(
                    children: [
                      Icon(Icons.comment, color: Colors.white, size: 28),
                      SizedBox(height: 4),
                      Text("55.3 mil", style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  // Compartidos
                  Column(
                    children: [
                      Icon(Icons.reply, color: Colors.white, size: 28),
                      SizedBox(height: 4),
                      Text("41.5 mil", style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // FILTRO DE TIEMPO + RANGO
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 🔽 DropdownMenu
                  DropdownMenu<String>(
                    initialSelection: "Rango de fechas",
                    dropdownMenuEntries: const [
                      DropdownMenuEntry(value: "Hoy", label: "Hoy"),
                      DropdownMenuEntry(value: "Ayer", label: "Ayer"),
                      DropdownMenuEntry(value: "Hace una semana", label: "Hace una semana"),
                      DropdownMenuEntry(value: "Hace dos semanas", label: "Hace dos semanas"),
                      DropdownMenuEntry(value: "Hace un mes", label: "Hace un mes"),
                      DropdownMenuEntry(value: "Hace seis mes", label: "Hace seis mes"),
                      DropdownMenuEntry(value: "Hace un año", label: "Hace un año"),
                    ],
                    inputDecorationTheme: InputDecorationTheme(
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    textStyle: const TextStyle(color: Colors.white),
                    trailingIcon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                    onSelected: (value) {
                      debugPrint("Seleccionado: $value");
                    },
                  ),
                  // rango fijo a la derecha, se puede cambiar para calcular los dias
                  const Text(
                    "18/1/2025 to 18/11/2025",
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // OVERVIEW CARD
              Card(
                color: Colors.grey[900],
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("Overview",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 12),
                      // filas de datos
                      _RowData(label: "Likes:", value: "3,100,000"),
                      _RowData(label: "Coments:", value: "55,300"),
                      _RowData(label: "Shared:", value: "41,500"),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // FOLLOWERS CARD
              Card(
                color: Colors.grey[900],
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("Followers",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 12),
                      _RowData(label: "Migozz", value: "60.2K"),
                      _RowData(label: "Tiktok", value: "40.1K"),
                      _RowData(label: "Instagram", value: "90.2K"),
                      _RowData(label: "All", value: "130.3K"),
                    ],
                  ),
                ),
              ),
            ]
          ),
        ),
      )
    );
  }
}

// Fila simple para datos (dejé esto como helper porque sino el código se repetiria arriba una y otra y otra vez)
// Igualmente se pueden llamar directamente los datos y ponerlos dependiendo de la 
class _RowData extends StatelessWidget {
  final String label;
  final String value;
  const _RowData({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
