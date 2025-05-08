import 'dart:io'; // Necesario para la clase File
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Necesario para Firebase Storage

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Método para guardar una receta favorita de un usuario
  Future<void> guardarRecetaFavorita(String recetaId) async {
    try {
      // Obtener el userId del usuario logueado
      User? user = _auth.currentUser;
      if (user == null) {
        print('No hay usuario logueado');
        return;
      }
      String userId = user.uid;

      // Referencia a la subcolección 'favoritas' del usuario
      CollectionReference favoritas = _firestore.collection('usuarios').doc(
          userId).collection('favoritas');

      // Obtener los datos de la receta desde la colección 'recetas'
      DocumentSnapshot recetaSnapshot = await _firestore.collection('recetas')
          .doc(recetaId)
          .get();

      if (recetaSnapshot.exists) {
        Map<String, dynamic> recetaData = recetaSnapshot.data() as Map<
            String,
            dynamic>;

        // Guardar la receta en la subcolección de favoritas
        await favoritas.doc(recetaId).set({
          'nombre': recetaData['nombre'],
          'categoria': recetaData['categoria'],
          'imagenUrl': recetaData['urlImagen'],
          'recetaID': recetaId,
        });

        print('Receta guardada como favorita');
      } else {
        print('Receta no encontrada');
      }
    } catch (e) {
      print('Error al guardar receta: $e');
    }
  }

  // Método para obtener las recetas favoritas de un usuario
  Future<List<Map<String, dynamic>>> obtenerRecetasFavoritas() async {
    try {
      // Obtener el userId del usuario logueado
      User? user = _auth.currentUser;
      if (user == null) {
        print('No hay usuario logueado');
        return [];
      }
      String userId = user.uid;

      // Obtener la lista de recetas favoritas del usuario
      QuerySnapshot querySnapshot = await _firestore.collection('usuarios').doc(
          userId).collection('favoritas').get();

      // Mapear los documentos a una lista de recetas
      List<Map<String, dynamic>> recetas = [];
      for (var doc in querySnapshot.docs) {
        recetas.add(doc.data() as Map<String, dynamic>);
      }

      return recetas;
    } catch (e) {
      print('Error al obtener recetas favoritas: $e');
      return [];
    }
  }
} // Fin de la clase FirebaseService

// Clase para manejar las operaciones de Firebase Storage
class StorageService { // Corregido: "class" en minúscula
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Método para subir un archivo a Firebase Storage
  Future<String?> subirArchivo(File archivo, String rutaDestino) async {
    try {
      // Crear una referencia a la ruta donde se guardará el archivo
      final ref = _storage.ref(rutaDestino);

      // Subir el archivo
      UploadTask uploadTask = ref.putFile(archivo);

      // Esperar a que la subida se complete
      final TaskSnapshot snapshot = await uploadTask;

      // Obtener la URL de descarga
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error al subir archivo: $e');
      return null;
    }
  }

  // Método para obtener la URL de descarga de un archivo
  Future<String?> obtenerUrlDescarga(String rutaArchivo) async {
    try {
      final ref = _storage.ref(rutaArchivo);
      final String downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error al obtener URL de descarga: $e');
      return null;
    }
  }

  // Método para eliminar un archivo de Firebase Storage
  Future<bool> eliminarArchivo(String rutaArchivo) async {
    try {
      final ref = _storage.ref(rutaArchivo);
      await ref.delete();
      print('Archivo eliminado: $rutaArchivo');
      return true;
    } catch (e) {
      print('Error al eliminar archivo: $e');
      return false;
    }
  }

  // Método para listar archivos en una "carpeta" (prefijo)
  Future<List<String>> listarArchivos(String prefijoCarpeta) async {
    List<String> nombresArchivos = [];
    try {
      final ListResult result = await _storage.ref(prefijoCarpeta).listAll();
      for (var item in result.items) {
        nombresArchivos.add(item.name); // Solo el nombre del archivo
      }
    } catch (e) {
      print('Error al listar archivos: $e');
    }
    return nombresArchivos;
  }
}