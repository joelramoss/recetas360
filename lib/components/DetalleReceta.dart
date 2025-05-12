import 'package:flutter/material.dart';
import 'package:recetas360/components/Receta.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recetas360/serveis/UsuarioUtil.dart';
import 'Receta.dart';
import 'nutritionalifno.dart';
import 'package:recetas360/components/PasosRecetaScreen.dart';
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
  final UsuarioUtil _usuarioUtil = UsuarioUtil();
  Map<String, bool> _ingredientesFaltantes = {};
  Map<String, bool> _ingredientesSeleccionados = {};

  @override
  void initState() {
    super.initState();
    _comentariosRef = FirebaseFirestore.instance.collection('comentarios');
    _cargarIngredientesFaltantes();
    for (var ing in widget.receta.ingredientes) {
      _ingredientesSeleccionados[ing] = false;
    }
  }

  Future<void> _cargarIngredientesFaltantes() async {
    String? userId = _usuarioUtil.getUidUsuarioActual();
    if (userId != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .collection('recetas_faltantes')
          .doc(widget.receta.id)
          .get();

      if (doc.exists) {
        final faltantes = Map<String, bool>.from(doc['ingredientes'] ?? {});
        setState(() {
          _ingredientesFaltantes = faltantes;
          // Sincroniza los checkboxes con lo que hay en Firestore
          for (var ing in widget.receta.ingredientes) {
            _ingredientesSeleccionados[ing] = faltantes[ing] ?? false;
          }
        });
      } else {
        setState(() {
          _ingredientesFaltantes = {};
          for (var ing in widget.receta.ingredientes) {
            _ingredientesSeleccionados[ing] = false;
          }
        });
      }
    }
  }

  Future<void> _guardarIngredientesFaltantes() async {
    String? userId = _usuarioUtil.getUidUsuarioActual();
    if (userId != null) {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .collection('recetas_faltantes')
          .doc(widget.receta.id)
          .set({
        'ingredientes': _ingredientesFaltantes,
        'recetaNombre': widget.receta.nombre,
      });
    }
  }

  void _marcarTodos(bool marcar) {
    setState(() {
      for (var ing in widget.receta.ingredientes) {
        _ingredientesSeleccionados[ing] = marcar;
        _ingredientesFaltantes[ing] = marcar;
      }
    });
    _guardarIngredientesFaltantes();
    for (var ing in widget.receta.ingredientes) {
      _actualizarCarrito(ing, marcar);
    }
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _agregarComentario(String comentario) async {
    try {
      String? idUsuarioActual = _usuarioUtil.getUidUsuarioActual();
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(idUsuarioActual)
          .get();
      String nombreUsuario = userDoc.get('nombre') ?? 'Usuario desconocido';

      await FirebaseFirestore.instance
          .collection('recetas')
          .doc(widget.receta.id)
          .collection('comentarios')
          .add({
        'comentario': comentario,
        'usuarioId': idUsuarioActual,
        'usuarioNombre': nombreUsuario,
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
    return FirebaseFirestore.instance
        .collection('recetas')
        .doc(widget.receta.id)
        .collection('comentarios')
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  Future<void> _actualizarCarrito(String ingrediente, bool seleccionado) async {
    String? userId = _usuarioUtil.getUidUsuarioActual();
    if (userId == null) return;
    final docRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .collection('recetas_faltantes')
        .doc(widget.receta.id);

    if (seleccionado) {
      // Añadir ingrediente al carrito
      await docRef.set({
        'ingredientes.$ingrediente': true,
      }, SetOptions(merge: true));
    } else {
      // Eliminar ingrediente del carrito
      await docRef.set({
        'ingredientes.$ingrediente': FieldValue.delete(),
      }, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receta.nombre),
        backgroundColor: Colors.orangeAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => _mostrarIngredientesFaltantes(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Row(
              children: [
                const Icon(Icons.timer, color: Colors.orangeAccent),
                const SizedBox(width: 8),
                Text("${widget.receta.tiempoMinutos} min"),
              ],
            ),
            const Divider(height: 32),
            const Text(
              "Ingredientes por comprar:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...widget.receta.ingredientes.map((ing) {
              return CheckboxListTile(
                title: Text(ing),
                value: _ingredientesSeleccionados[ing] ?? false,
                onChanged: (bool? value) async {
                  setState(() {
                    _ingredientesSeleccionados[ing] = value ?? false;
                    _ingredientesFaltantes[ing] = value ?? false;
                  });
                  await _guardarIngredientesFaltantes();
                  await _actualizarCarrito(ing, value ?? false);
                },
              );
            }).toList(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _marcarTodos(true),
                  child: const Text("Marcar todos"),
                ),
                ElevatedButton(
                  onPressed: () => _marcarTodos(false),
                  child: const Text("Marcar ninguno"),
                ),
              ],
            ),
            const Divider(height: 32),
            const Text(
              "Descripción:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(widget.receta.descripcion),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PasosRecetaScreen(receta: widget.receta),
                  ),
                );
              },
              child: const Text(
                "Iniciar",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 32),
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
                    final esUsuarioActual =
                        comentario['usuarioId'] == _usuarioUtil.getUidUsuarioActual();

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
                                    (comentario['usuarioNombre'] != null &&
                                            comentario['usuarioNombre'].isNotEmpty)
                                        ? comentario['usuarioNombre'][0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  comentario['usuarioNombre'] ?? 'Usuario desconocido',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (esUsuarioActual) ...[
                                  const SizedBox(width: 8),
                                  const Text(
                                    '(Tú)',
                                    style: TextStyle(
                                        color: Colors.orangeAccent,
                                        fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(comentario['comentario'] ?? 'Sin comentario'),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                _formatearFecha(fecha),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
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

  void _mostrarIngredientesFaltantes(BuildContext context) {
    List<String> faltantes = _ingredientesFaltantes.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ingredientes faltantes - ${widget.receta.nombre}'),
        content: faltantes.isEmpty
            ? const Text('¡No te falta nada para esta receta!')
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: faltantes.map((ing) => Text('- $ing')).toList(),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}