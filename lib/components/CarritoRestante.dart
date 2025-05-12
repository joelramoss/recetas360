import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recetas360/serveis/UsuarioUtil.dart';
import 'package:recetas360/components/Receta.dart';
import 'package:recetas360/components/DetalleReceta.dart';

class CarritoFaltantes extends StatefulWidget {
  const CarritoFaltantes({Key? key}) : super(key: key);

  @override
  _CarritoFaltantesState createState() => _CarritoFaltantesState();
}

class _CarritoFaltantesState extends State<CarritoFaltantes> {
  final UsuarioUtil _usuarioUtil = UsuarioUtil();
  Map<String, Map<String, bool>> _ingredientesFaltantesPorReceta = {};

  Stream<QuerySnapshot> _cargarRecetasFaltantes() {
    String? userId = _usuarioUtil.getUidUsuarioActual();
    if (userId == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .collection('recetas_faltantes')
        .snapshots();
  }

  Future<void> _actualizarIngrediente(String recetaId, String ingrediente, bool nuevoEstado) async {
    String? userId = _usuarioUtil.getUidUsuarioActual();
    if (userId != null) {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .collection('recetas_faltantes')
          .doc(recetaId)
          .update({
        'ingredientes.$ingrediente': nuevoEstado,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orangeAccent,
        title: const Text('Carrito de compra'),
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
                  "Ingredientes Faltantes en tus Recetas",
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
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _cargarRecetasFaltantes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No hay recetas con ingredientes faltantes",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    );
                  }

                  final recetasConFaltantes = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final ingredientes = Map<String, bool>.from(data['ingredientes'] ?? {});
                    _ingredientesFaltantesPorReceta[doc.id] = ingredientes;
                    return ingredientes.values.any((faltante) => faltante);
                  }).toList();

                  if (recetasConFaltantes.isEmpty) {
                    return const Center(
                      child: Text(
                        "¡No te falta nada en tus recetas!",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: recetasConFaltantes.length,
                    itemBuilder: (context, index) {
                      final doc = recetasConFaltantes[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final ingredientes = _ingredientesFaltantesPorReceta[doc.id] ?? {};
                      final faltantes = ingredientes.entries
                          .where((entry) => entry.value)
                          .map((entry) => entry.key)
                          .toList();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        child: ExpansionTile(
                          title: Text(
                            data['recetaNombre'] ?? 'Receta sin nombre',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          children: faltantes.map((ingrediente) {
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: ingredientes[ingrediente] == true
                                    ? Colors.redAccent
                                    : Colors.greenAccent,
                                child: Icon(
                                  ingredientes[ingrediente] == true
                                      ? Icons.local_grocery_store
                                      : Icons.check,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(ingrediente),
                              onTap: () {
                                setState(() {
                                  ingredientes[ingrediente] = !ingredientes[ingrediente]!;
                                });
                                _actualizarIngrediente(doc.id, ingrediente, !ingredientes[ingrediente]!);

                                if (!ingredientes.values.any((faltante) => faltante)) {
                                  _ingredientesFaltantesPorReceta.remove(doc.id);
                                }
                              },
                              onLongPress: () {
                                FirebaseFirestore.instance
                                    .collection('recetas')
                                    .doc(doc.id)
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
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Placeholder action: muestra un SnackBar
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Información enviada (funcionalidad placeholder)'),
                    ),
                  );
                  // Aquí puedes agregar la lógica para enviar la información
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'Enviar Información',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}