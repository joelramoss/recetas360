// usuario_util.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UsuarioUtil {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtiene el UID del usuario actual autenticado.
  String? getUidUsuarioActual() {
    return _auth.currentUser?.uid;
  }

  /// Obtiene el nombre del usuario actual desde Firestore.
  Future<String> getNombreUsuarioActual() async {
    final user = _auth.currentUser;
    if (user == null) {
      return "Usuario no autenticado";
    }
    try {
      final userDoc = await _firestore.collection('usuarios').doc(user.uid).get();
      if (userDoc.exists) {
        return userDoc.data()?['nombre'] ?? 'Usuario desconocido';
      } else {
        return "Usuario no encontrado en la base de datos";
      }
    } catch (e) {
      print('Error al obtener nombre del usuario: $e');
      return 'Error al obtener nombre';
    }
  }

  /// Agrega un comentario a Firestore asociado a una receta.
  Future<void> agregarComentario(String recetaId, String texto) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("Usuario no autenticado");
    }
    final nombreUsuario = await getNombreUsuarioActual();
    await _firestore.collection('comentarios').add({
      'recetaId': recetaId,
      'usuarioId': user.uid,
      'usuarioNombre': nombreUsuario,
      'texto': texto,
      'fecha': FieldValue.serverTimestamp(),
      'likes': 0,
    });
  }

  /// Borra un comentario de Firestore dado su ID.
  Future<void> borrarComentario(String comentarioId) async {
    await _firestore.collection('comentarios').doc(comentarioId).delete();
  }
}