import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recetas360/serveis/UsuarioUtil.dart';
import 'package:recetas360/components/Receta.dart';
import 'package:recetas360/components/DetalleReceta.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Importar flutter_animate

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
    if (userId == null) return;
    
    final ingredientesFaltantes = _ingredientesFaltantesPorReceta[recetaId] ?? {};
    ingredientesFaltantes[ingrediente] = nuevoEstado;
    
    final docRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .collection('recetas_faltantes')
        .doc(recetaId);
        
    try {
      if (nuevoEstado) {
        await docRef.set({
          'ingredientes': {ingrediente: true},
          'actualizadoEn': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        await docRef.update({
          'ingredientes.$ingrediente': FieldValue.delete(),
        });
        
        final sigueHabiendoFaltantes = ingredientesFaltantes.values.any((faltante) => faltante);
        
        if (!sigueHabiendoFaltantes) {
          await docRef.delete();
          setState(() {
            _ingredientesFaltantesPorReceta.remove(recetaId);
          });
        }
      }
    } catch (e) {
      print("Error al actualizar el ingrediente: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        // backgroundColor: Colors.orangeAccent, // Se usará el color del tema
        title: const Text('Carrito de Compra'), // Título más descriptivo
      ),
      body: Column( // Mantenemos Column para la estructura general
          children: [
            Padding( // Usamos Padding como en PantallaGastronomias
              padding:
                  const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
              child: Text(
                "Ingredientes Faltantes", // Título más corto y directo
                style: textTheme.headlineMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms, duration: 500.ms), // Animación
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _cargarRecetasFaltantes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: colorScheme.primary));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        "No hay ingredientes faltantes en tus recetas.",
                        style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 100.ms),
                    );
                  }

                  final recetasConFaltantes = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final ingredientes = Map<String, bool>.from(data['ingredientes'] ?? {});
                    _ingredientesFaltantesPorReceta[doc.id] = ingredientes;
                    return ingredientes.values.any((faltante) => faltante);
                  }).toList();

                  if (recetasConFaltantes.isEmpty) {
                    return Center(
                      child: Text(
                        "¡No te falta nada en tus recetas!",
                        style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 100.ms),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Padding ajustado
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
                        margin: const EdgeInsets.only(bottom: 12), // Margen ajustado
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2, // Elevación sutil
                        clipBehavior: Clip.antiAlias, // Para que el ExpansionTile respete el borde
                        child: ExpansionTile(
                          backgroundColor: colorScheme.surfaceContainerLowest, // Color de fondo para el tile expandido
                          collapsedBackgroundColor: colorScheme.surface, // Color de fondo para el tile colapsado
                          iconColor: colorScheme.primary,
                          collapsedIconColor: colorScheme.onSurfaceVariant,
                          title: Text(
                            data['recetaNombre'] ?? 'Receta sin nombre',
                            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          children: faltantes.map((ingrediente) {
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24, // Aumentar padding horizontal para los items
                                vertical: 8,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: ingredientes[ingrediente] == true
                                    ? colorScheme.errorContainer // Usar colores del tema
                                    : colorScheme.primaryContainer,
                                child: Icon(
                                  ingredientes[ingrediente] == true
                                      ? Icons.remove_shopping_cart_outlined // Icono más representativo
                                      : Icons.check_circle_outline_rounded,
                                  color: ingredientes[ingrediente] == true
                                      ? colorScheme.onErrorContainer
                                      : colorScheme.onPrimaryContainer,
                                ),
                              ),
                              title: Text(ingrediente, style: textTheme.bodyLarge),
                              onTap: () {
                                final estadoActual = ingredientes[ingrediente] ?? true;
                                setState(() {
                                  ingredientes[ingrediente] = !estadoActual;
                                });
                                _actualizarIngrediente(doc.id, ingrediente, !estadoActual);
                              },
                              onLongPress: () {
                                FirebaseFirestore.instance
                                    .collection('recetas')
                                    .doc(doc.id) // Usar doc.id que es el ID de la receta faltante, no el nombre
                                    .get()
                                    .then((recetaDoc) {
                                  if (recetaDoc.exists) {
                                    final recetaData = recetaDoc.data()!;
                                    // recetaData['id'] = recetaDoc.id; // El ID ya está en recetaDoc.id

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DetalleReceta(
                                          receta: Receta.fromFirestore(recetaData, recetaDoc.id),
                                        ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Esta receta ya no está disponible', style: TextStyle(color: colorScheme.onError)),
                                        backgroundColor: colorScheme.error,
                                      ),
                                    );
                                  }
                                }).catchError((error) {
                                  print("Error al cargar detalles de receta: $error");
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error al cargar la receta', style: TextStyle(color: colorScheme.onError)),
                                      backgroundColor: colorScheme.error,
                                    ),
                                  );
                                });
                              },
                            );
                          }).toList().animate(interval: 50.ms).fadeIn().slideX(begin: 0.1), // Animación para los items
                        ),
                      ).animate().fadeIn(delay: (index * 50).ms, duration: 300.ms).slideY(begin: 0.1); // Animación para las tarjetas
                    },
                  );
                },
              ),
            ),
            Padding( // Padding para el botón
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon( // Cambiado a ElevatedButton.icon
                icon: const Icon(Icons.send_rounded), // Icono para el botón
                label: const Text(
                  'Enviar Información',
                  // style: textTheme.labelLarge?.copyWith(color: colorScheme.onPrimary), // Estilo del tema
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Información enviada (funcionalidad placeholder)'),
                      backgroundColor: colorScheme.secondaryContainer,
                      behavior: SnackBarBehavior.floating, // Estilo flotante
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary, // Usar color primario del tema
                  foregroundColor: colorScheme.onPrimary,
                  minimumSize: const Size(double.infinity, 50), // Botón más ancho
                  // padding: const EdgeInsets.symmetric(vertical: 16), // Padding ya aplicado por minimumSize
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2), // Animación para el botón
            ),
          ],
        ),
    );
  }
}