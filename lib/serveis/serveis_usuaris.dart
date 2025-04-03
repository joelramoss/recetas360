import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsuarioActual {
  final String email;
  final String uid;
  final String nombre;
  final User? currentUser;

  UsuarioActual({
    required this.email,
    required this.uid,
    required this.nombre,
    required this.currentUser,
  });
}

Future<UsuarioActual> obtenerUsuarioActual() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    throw Exception("No hay usuario autenticado");
  }

  try {
    // Obtener los datos del usuario desde Firestore
    final doc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();

    String nombreUsuario = 'Usuario desconocido';
    if (doc.exists) {
      final data = doc.data();
      nombreUsuario = data?['nombre'] ?? 'Usuario desconocido';
    }

    return UsuarioActual(
      email: user.email ?? 'Email no disponible',
      uid: user.uid,
      nombre: nombreUsuario,
      currentUser: user,  // Aquí se pasa el usuario actual de Firebase
    );
  } catch (e) {
    print("Error obteniendo datos del usuario: $e");
    throw Exception("Error obteniendo datos del usuario");
  }
}
