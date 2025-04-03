import 'package:flutter/material.dart';
import 'package:recetas360/components/Receta.dart';
import 'package:recetas360/components/nutritionalifno.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DetalleReceta extends StatefulWidget {
  final Receta receta;

  const DetalleReceta({Key? key, required this.receta}) : super(key: key);

  @override
  _DetalleRecetaState createState() => _DetalleRecetaState();
}

class _DetalleRecetaState extends State<DetalleReceta> {
  final TextEditingController _comentarioController = TextEditingController();
  late CollectionReference _comentariosRef;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _comentariosRef = FirebaseFirestore.instance.collection('comentarios');
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _agregarComentario(String comentario) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes iniciar sesión para comentar')),
        );
        return;
      }

      await _comentariosRef.add({
        'recetaId': widget.receta.id,
        'comentario': comentario,
        'usuarioId': user.uid,
        'usuarioEmail': user.email,
        'usuarioNombre': user.displayName ?? user.email!.split('@')[0],
        'fecha': FieldValue.serverTimestamp(),
      });
      _comentarioController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comentario agregado')),
      );
    } catch (e) {
      print('Error al agregar comentario: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al agregar comentario: ${e.toString()}')),
      );
    }
  }

  Stream<QuerySnapshot> _cargarComentarios() {
    return _comentariosRef
        .where('recetaId', isEqualTo: widget.receta.id)
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receta.nombre),
        backgroundColor: Colors.orangeAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen de la receta
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.receta.urlImagen,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 50),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Información básica
            Row(
              children: [
                const Icon(Icons.timer, color: Colors.orangeAccent),
                const SizedBox(width: 8),
                Text("${widget.receta.tiempoMinutos} min"),
              ],
            ),
            
            const Divider(height: 32),
            
            // Ingredientes
            const Text(
              "Ingredientes:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...widget.receta.ingredientes.map((ing) {
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(ing),
              );
            }).toList(),
            
            const Divider(height: 32),
            
            // Descripción
            const Text(
              "Descripción:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(widget.receta.descripcion),
            
            const Divider(height: 32),
            
            // SECCIÓN DE COMENTARIOS MEJORADA
            const Text(
              "Comentarios:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            StreamBuilder<QuerySnapshot>(
              stream: _cargarComentarios(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Text(
                    'Error: ${snapshot.error.toString()}',
                    style: const TextStyle(color: Colors.red),
                  );
                }

                final comentarios = snapshot.data!.docs;
                
                if (comentarios.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No hay comentarios aún. ¡Sé el primero en comentar!',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  );
                }

                return Column(
                  children: comentarios.map((doc) {
                    final comentario = doc.data() as Map<String, dynamic>;
                    final fecha = comentario['fecha'] != null 
                        ? (comentario['fecha'] as Timestamp).toDate() 
                        : DateTime.now();
                    final esUsuarioActual = comentario['usuarioId'] == _auth.currentUser?.uid;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: esUsuarioActual ? Colors.orange[50] : null,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Colors.orangeAccent,
                                  child: Text(
                                    comentario['usuarioNombre'][0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  comentario['usuarioNombre'],
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (esUsuarioActual) ...[
                                  const SizedBox(width: 8),
                                  const Text(
                                    '(Tú)',
                                    style: TextStyle(
                                      color: Colors.orangeAccent,
                                      fontStyle: FontStyle.italic
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(comentario['comentario']),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                _formatearFecha(fecha),
                                style: const TextStyle(
                                  fontSize: 12, 
                                  color: Colors.grey
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Formulario para nuevo comentario
            const Text(
              "Añadir comentario:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _comentarioController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Escribe tu comentario aquí...",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                final comentarioTexto = _comentarioController.text.trim();
                if (comentarioTexto.isNotEmpty) {
                  _agregarComentario(comentarioTexto);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('El comentario no puede estar vacío')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Publicar Comentario"),
            ),
          ],
        ),
      ),
    );
  }
}