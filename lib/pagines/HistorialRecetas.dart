import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recetas360/components/DetalleReceta.dart';
import 'package:recetas360/components/Receta.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistorialRecetas extends StatefulWidget {
  const HistorialRecetas({Key? key}) : super(key: key);

  @override
  _HistorialRecetasState createState() => _HistorialRecetasState();
}

class _HistorialRecetasState extends State<HistorialRecetas> {
  @override
  Widget build(BuildContext context) {
    // Obtener el usuario actual
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String userId = currentUser?.uid ?? 'usuario_anonimo';
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orangeAccent,
        title: const Text('Historial de Recetas'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.orangeAccent,
              Colors.pink.shade100,
            ],
          ),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 50,
              child: const Center(
                child: Text(
                  "Recetas Completadas",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 4,
                        color: Colors.black45,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Lista de recetas filtradas por usuario sin ordenamiento complejo
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('recetas_completadas')
                    .where('usuario_id', isEqualTo: userId)
                    // Eliminado el orderBy para evitar necesitar un índice compuesto
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "Aún no has completado ninguna receta",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    );
                  }
                  
                  // Ordenar localmente en lugar de hacerlo en la consulta
                  final docs = snapshot.data!.docs.toList()
                    ..sort((a, b) {
                      final aTime = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                      final bTime = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                      if (aTime == null) return 1;
                      if (bTime == null) return -1;
                      return bTime.compareTo(aTime); // Ordenar de más reciente a más antiguo
                    });
                  
                  // Agrupar documentos por gastronomía
                  final Map<String, List<DocumentSnapshot>> recetasPorGastronomia = {};
                  
                  for (final doc in docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final gastronomia = data['gastronomia'] ?? 'Otra';
                    
                    if (!recetasPorGastronomia.containsKey(gastronomia)) {
                      recetasPorGastronomia[gastronomia] = [];
                    }
                    
                    recetasPorGastronomia[gastronomia]!.add(doc);
                  }
                  
                  // Construir lista expandible por gastronomía
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: recetasPorGastronomia.length,
                    itemBuilder: (context, index) {
                      final gastronomia = recetasPorGastronomia.keys.toList()[index];
                      final recetas = recetasPorGastronomia[gastronomia]!;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        child: ExpansionTile(
                          title: Text(
                            gastronomia,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          children: recetas.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final fecha = (data['fecha_completado'] as Timestamp?)?.toDate();
                            final fechaFormateada = fecha != null 
                                ? "${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}"
                                : "Fecha desconocida";
                            
                            // ListTile simplificado sin imagen
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: Colors.orangeAccent,
                                child: Icon(
                                  _getCategoryIcon(data['categoria'] ?? ''),  // Icono basado en la categoría
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(data['nombre'] ?? 'Sin nombre'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Mostrar tanto la categoría como la fecha
                                  Text('${data['categoria'] ?? 'Sin categoría'} • ${fechaFormateada}',
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  // Opcionalmente mostrar el tipo de gastronomía aquí también
                                  Text('Gastronomía: ${data['gastronomia'] ?? 'Otra'}',
                                      style: TextStyle(fontSize: 12)),
                                ],
                              ),
                              onTap: () {
                                // Recuperar la receta completa desde Firestore
                                FirebaseFirestore.instance
                                    .collection('recetas')
                                    .doc(data['receta_id'])
                                    .get()
                                    .then((recetaDoc) {
                                  if (recetaDoc.exists) {
                                    final recetaData = recetaDoc.data()!;
                                    recetaData['id'] = recetaDoc.id;
                                    
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DetalleReceta(
                                          receta: Receta.fromFirestore(recetaData),
                                        ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Esta receta ya no está disponible'),
                                      ),
                                    );
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Agregar este método a la clase _HistorialRecetasState
  IconData _getCategoryIcon(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'carne':
        return Icons.restaurant_menu;
      case 'pescado':
      case 'mariscos':
        return Icons.set_meal;
      case 'vegetariana':
      case 'vegana':
        return Icons.eco;
      case 'postre':
        return Icons.cake;
      case 'bebida':
        return Icons.local_bar;
      case 'pasta':
      case 'arroz':
        return Icons.dinner_dining;
      case 'desayuno':
        return Icons.free_breakfast;
      default:
        return Icons.restaurant;
    }
  }
}