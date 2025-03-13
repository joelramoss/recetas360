import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<User?> registrarUsuario(String email, String password) async {
  try {
    UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential.user; // Devuelve el usuario si se registra correctamente
  } catch (e) {
    print("Error al registrar usuario: $e");
    return null;
  }
}

Future<User?> iniciarSesion(String email, String password) async {
  try {
    UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential.user;
  } catch (e) {
    print("Error al iniciar sesión: $e");
    return null;
  }
}



Future<void> guardarUsuarioEnFirestore(User user, String nombre) async {
  await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).set({
    'uid': user.uid,
    'nombre': nombre,
    'email': user.email,
    'fecha_creacion': FieldValue.serverTimestamp(),
  });
}

