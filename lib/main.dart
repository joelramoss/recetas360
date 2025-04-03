import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:recetas360/pagines/PaginaLogin.dart';
import 'firebase_options.dart'; // Asegúrate de que este archivo existe

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Se eliminó la inicialización del servicio de notificaciones
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Oculta la etiqueta de debug
      title: 'Recetas360',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true, // Usa Material 3 para un mejor diseño
      ),
      home: const Paginalogin(), // Usa const para optimizar
    );
  }
}
