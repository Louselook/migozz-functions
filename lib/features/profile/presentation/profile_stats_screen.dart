import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileStatsScreen extends StatefulWidget {
  const ProfileStatsScreen({super.key});

  @override
  State<ProfileStatsScreen> createState() => _ProfileStatsScreenState();
}

class _ProfileStatsScreenState extends State<ProfileStatsScreen> {
  DateTimeRange? selectedRange;

  // Cargar datos del usuario
  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        debugPrint('Datos de usuario: ${doc.data()}');
      }
    } catch (e) {
      debugPrint('Error cargando usuario: $e');
    }
  }

  // Mostrar el DateRangePicker
  Future<void> _pickDateRange() async {
    final DateTime now = DateTime.now();

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1990, 1, 1),
      lastDate: now,
      initialDateRange: selectedRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 7)),
            end: now,
          ),
      helpText: 'Selecciona el rango de fechas',
      saveText: 'Seleccionar',
    );

    if (picked != null) {
      setState(() {
        selectedRange = picked;
      });
    }
  }

  // Texto formateado del rango
  String get rangeText {
    if (selectedRange == null) return "No seleccionado";
    final start = selectedRange!.start;
    final end = selectedRange!.end;
    return "${start.day}/${start.month}/${start.year} → ${end.day}/${end.month}/${end.year}";
  }

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
              //  Metricas arriba :p
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  _Metric(icon: Icons.favorite, label: "3.1 mill."),
                  _Metric(icon: Icons.comment, label: "55.3 mil"),
                  _Metric(icon: Icons.reply, label: "41.5 mil"),
                ],
              ),
              const SizedBox(height: 20),

              //  FILTRO DE TIEMPO + RANGO
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _pickDateRange,
                    child: const Text("Seleccionar fecha"),
                  ),
                  Text(
                    rangeText,
                    style: const TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              //  Card superior
              _DataCard(
                title: "Overview",
                rows: const [
                  _RowData(label: "Likes:", value: "3,100,000"),
                  _RowData(label: "Comments:", value: "55,300"),
                  _RowData(label: "Shared:", value: "41,500"),
                ],
              ),
              const SizedBox(height: 16),

              //  Card inferior
              _DataCard(
                title: "Followers",
                rows: const [
                  _RowData(label: "Migozz:", value: "60.2K"),
                  _RowData(label: "Tiktok:", value: "40.1K"),
                  _RowData(label: "Instagram:", value: "90.2K"),
                  _RowData(label: "All:", value: "130.3K"),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// Complementos
// ------------------------------------------------------------

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Metric({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}

class _DataCard extends StatelessWidget {
  final String title;
  final List<_RowData> rows;
  const _DataCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Card(
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
          children: [
            Text(title,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...rows,
          ],
        ),
      ),
    );
  }
}

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
