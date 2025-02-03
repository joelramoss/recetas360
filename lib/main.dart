import 'package:flutter/material.dart';
import 'package:recetas360/pagines/PaginaLogin.dart';  // Importa la clase Paginalogin

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recetas360',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Paginalogin(), // Aquí se llama la clase Paginalogin
    );
  }
}
