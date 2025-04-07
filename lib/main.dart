import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recetas360/pagines/PaginaLogin.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Verificar si la actualización ya se ha realizado
  DocumentSnapshot configDoc = await FirebaseFirestore.instance
      .collection('configuraciones')
      .doc('actualizacion_nombres')
      .get();

  bool actualizacionCompletada = configDoc.exists && configDoc.get('completada') == true;

  if (!actualizacionCompletada) {
    await actualizarNombresEnComentarios();
    // Marcar la actualización como completada
    await FirebaseFirestore.instance
        .collection('configuraciones')
        .doc('actualizacion_nombres')
        .set({'completada': true});
  }

  runApp(const MyApp());
}

// Método para actualizar los nombres en los comentarios
Future<void> actualizarNombresEnComentarios() async {
  try {
    QuerySnapshot comentariosSnapshot =
        await FirebaseFirestore.instance.collection('comentarios').get();

    for (var comentarioDoc in comentariosSnapshot.docs) {
      // Verificar si el campo usuarioId existe
      if (comentarioDoc.data().toString().contains('usuarioId')) {
        String usuarioId = comentarioDoc.get('usuarioId');
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(usuarioId)
            .get();

        if (userDoc.exists) {
          String nombreUsuario = userDoc.get('nombre') ?? 'Usuario desconocido';
          await comentarioDoc.reference.update({
            'usuarioNombre': nombreUsuario,
          });
        } else {
          print('Usuario no encontrado para usuarioId: $usuarioId');
        }
      } else {
        print('Comentario sin usuarioId: ${comentarioDoc.id}');
      }
    }
    print('Comentarios actualizados exitosamente');
  } catch (e) {
    print('Error al actualizar comentarios: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Recetas360',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const Paginalogin(),
    );
  }
}