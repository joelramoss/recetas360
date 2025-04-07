import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      CollectionReference favoritas = _firestore.collection('usuarios').doc(userId).collection('favoritas');

      // Obtener los datos de la receta desde la colección 'recetas'
      DocumentSnapshot recetaSnapshot = await _firestore.collection('recetas').doc(recetaId).get();

      if (recetaSnapshot.exists) {
        Map<String, dynamic> recetaData = recetaSnapshot.data() as Map<String, dynamic>;

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
      QuerySnapshot querySnapshot = await _firestore.collection('usuarios').doc(userId).collection('favoritas').get();

      // Mapear los documentos a una lista de recetas
      List<Map<String, dynamic>> recetas = [];
      querySnapshot.docs.forEach((doc) {
        recetas.add(doc.data() as Map<String, dynamic>);
      });

      return recetas;
    } catch (e) {
      print('Error al obtener recetas favoritas: $e');
      return [];
    }
  }
}
