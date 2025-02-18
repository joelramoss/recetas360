import 'package:flutter/material.dart';
import 'package:recetas360/pagines/PaginaLogin.dart';  // Importa la clase Paginalogin
import 'package:recetas360/pagines/InterfazAjustes.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
      debugShowCheckedModeBanner: false,
    return MaterialApp(
      title: 'Recetas360',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Paginalogin(), // Aquí se llama la clase Paginalogin
    );
  }
}
