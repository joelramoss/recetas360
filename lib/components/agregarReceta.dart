import 'package:cloud_firestore/cloud_firestore.dart';
import 'Receta.dart';

// Función para agregar la receta a Firestore (colección 'recetas')
Future<void> agregarReceta(Receta receta) async {
  await FirebaseFirestore.instance.collection('recetas').add(
    receta.toMap(),
  );
}
