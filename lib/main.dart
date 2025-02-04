import 'package:flutter/material.dart';
import 'package:recetas360/pagines/InterfazAjustes.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      // Puedes quitar debugShowCheckedModeBanner si lo deseas
      debugShowCheckedModeBanner: true,
      home: PaginaAjustes(),
    );
  }
}
