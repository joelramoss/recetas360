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
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Sube un archivo a Firebase Storage y devuelve la URL de descarga.
  /// Retorna null si la subida falla.
  Future<String?> subirArchivo(File file, String destinationPath) async {
    try {
      final ref = _storage.ref(destinationPath);
      UploadTask uploadTask = ref.putFile(file);
      
      // Espera a que la tarea se complete
      TaskSnapshot snapshot = await uploadTask;

      if (snapshot.state == TaskState.success) {
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        print("Archivo subido exitosamente: $downloadUrl");
        return downloadUrl;
      } else {
        print("La subida del archivo falló, estado: ${snapshot.state}");
        return null;
      }
    } on FirebaseException catch (e) {
      print("FirebaseException al subir archivo ($destinationPath): ${e.code} - ${e.message}");
      return null;
    } catch (e) {
      print("Excepción genérica al subir archivo ($destinationPath): $e");
      return null;
    }
  }

  /// Elimina un archivo de Firebase Storage usando su URL de descarga.
  /// Esto es un "mejor esfuerzo" y puede no funcionar para todos los formatos de URL o si los permisos son estrictos.
  Future<void> eliminarArchivoPorUrl(String url) async {
    if (url.isEmpty || !url.startsWith("https://firebasestorage.googleapis.com")) {
      print("URL inválida o no es de Firebase Storage para eliminar: $url");
      return;
    }
    try {
      Reference ref = _storage.refFromURL(url);
      await ref.delete();
      print("Archivo eliminado de Storage (por URL): $url");
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        print("El archivo no existía en Storage (por URL), no se necesita eliminar: $url");
      } else {
        print("FirebaseException al eliminar archivo por URL ($url): ${e.code} - ${e.message}");
      }
    } catch (e) {
      print("Excepción genérica al eliminar archivo por URL ($url): $e");
    }
  }

  // Sería ideal tener un método para eliminar por ruta si guardas la ruta en Firestore
  Future<void> eliminarArchivoPorRuta(String storagePath) async {
    if (storagePath.isEmpty) return;
    try {
      Reference ref = _storage.ref(storagePath);
      await ref.delete();
      print("Archivo eliminado de Storage (por ruta): $storagePath");
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        print("El archivo no existía en Storage (por ruta), no se necesita eliminar: $storagePath");
      } else {
        print("FirebaseException al eliminar archivo por ruta ($storagePath): ${e.code} - ${e.message}");
      }
    } catch (e) {
      print("Excepción genérica al eliminar archivo por ruta ($storagePath): $e");
    }
  }
}