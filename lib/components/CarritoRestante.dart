import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:recetas360/serveis/UsuarioUtil.dart';
import 'package:recetas360/components/Receta.dart';
import 'package:recetas360/components/DetalleReceta.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CarritoFaltantes extends StatefulWidget {
  const CarritoFaltantes({Key? key}) : super(key: key);

  @override
  _CarritoFaltantesState createState() => _CarritoFaltantesState();
}

class _CarritoFaltantesState extends State<CarritoFaltantes> {
  final UsuarioUtil _usuarioUtil = UsuarioUtil();
  Map<String, ({Map<String, bool> ingredientes, String? nombreReceta})> _datosFaltantesPorReceta = {};

  @override
  void initState() {
    super.initState();
  }

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

    final ingredientesFaltantes = _datosFaltantesPorReceta[recetaId]?.ingredientes ?? {};
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
          'recetaNombre': _datosFaltantesPorReceta[recetaId]?.nombreReceta ?? (await FirebaseFirestore.instance.collection('recetas').doc(recetaId).get()).data()?['nombre'] ?? 'Receta Desconocida',
        }, SetOptions(merge: true));
      } else {
        await docRef.update({
          'ingredientes.$ingrediente': FieldValue.delete(),
        });

        final dataActual = (await docRef.get()).data();
        final ingredientesRestantes = Map<String, bool>.from(dataActual?['ingredientes'] ?? {});
        final sigueHabiendoFaltantes = ingredientesRestantes.values.any((faltante) => faltante);

        if (!sigueHabiendoFaltantes) {
          await docRef.delete();
          if (mounted) {
            setState(() {
              _datosFaltantesPorReceta.remove(recetaId);
            });
          }
        }
      }
    } catch (e) {
      print("Error al actualizar el ingrediente: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar ingrediente: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrito de Compra'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
            child: Text(
              "Ingredientes Faltantes",
              style: textTheme.headlineMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
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
                      "No hay ingredientes faltantes.",
                      style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 100.ms),
                  );
                }

                _datosFaltantesPorReceta.clear();
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final Map<String, dynamic> ingredientesRaw = data['ingredientes'] as Map<String, dynamic>? ?? {};
                  final Map<String, bool> ingredientesTyped = {};
                  ingredientesRaw.forEach((key, value) {
                    if (value is bool) {
                      ingredientesTyped[key] = value;
                    } else {
                      print("ADVERTENCIA: Ingrediente '$key' para receta ${doc.id} no es booleano, es ${value.runtimeType}. Se omitirá.");
                    }
                  });

                  _datosFaltantesPorReceta[doc.id] = (
                    ingredientes: ingredientesTyped,
                    nombreReceta: data['recetaNombre'] as String?
                  );
                }

                final recetasConFaltantes = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final Map<String, dynamic> ingredientesRaw = data['ingredientes'] as Map<String, dynamic>? ?? {};
                  return ingredientesRaw.values.any((faltante) => faltante is bool && faltante == true);
                }).toList();

                if (recetasConFaltantes.isEmpty) {
                  return Center(
                    child: Text(
                      "¡No te falta nada!",
                      style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 100.ms),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: recetasConFaltantes.length,
                  itemBuilder: (context, index) {
                    final doc = recetasConFaltantes[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final ingredientes = _datosFaltantesPorReceta[doc.id]?.ingredientes ?? {};
                    final faltantes = ingredientes.entries
                        .where((entry) => entry.value)
                        .map((entry) => entry.key)
                        .toList();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      clipBehavior: Clip.antiAlias,
                      child: ExpansionTile(
                        backgroundColor: colorScheme.surfaceContainerLowest,
                        collapsedBackgroundColor: colorScheme.surface,
                        iconColor: colorScheme.primary,
                        collapsedIconColor: colorScheme.onSurfaceVariant,
                        title: Text(
                          _datosFaltantesPorReceta[doc.id]?.nombreReceta ?? data['recetaNombre'] ?? 'Receta sin nombre',
                          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        children: faltantes.map((ingrediente) {
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: ingredientes[ingrediente] == true
                                  ? colorScheme.errorContainer
                                  : colorScheme.primaryContainer,
                              child: Icon(
                                ingredientes[ingrediente] == true
                                    ? Icons.remove_shopping_cart_outlined
                                    : Icons.check_circle_outline_rounded,
                                color: ingredientes[ingrediente] == true
                                    ? colorScheme.onErrorContainer
                                    : colorScheme.onPrimaryContainer,
                              ),
                            ),
                            title: Text(ingrediente, style: textTheme.bodyLarge),
                            onTap: () {
                              final estadoActual = ingredientes[ingrediente] ?? true;
                              _actualizarIngrediente(doc.id, ingrediente, !estadoActual);
                            },
                            onLongPress: () {
                              FirebaseFirestore.instance
                                  .collection('recetas')
                                  .doc(doc.id)
                                  .get()
                                  .then((recetaDoc) {
                                if (recetaDoc.exists) {
                                  final recetaData = recetaDoc.data()!;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DetalleReceta(
                                        receta: Receta.fromFirestore(recetaData, recetaDoc.id),
                                      ),
                                    ),
                                  );
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Esta receta ya no está disponible', style: TextStyle(color: colorScheme.onError)),
                                        backgroundColor: colorScheme.error,
                                      ),
                                    );
                                  }
                                }
                              }).catchError((error) {
                                print("Error al cargar detalles de receta: $error");
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error al cargar la receta', style: TextStyle(color: colorScheme.onError)),
                                      backgroundColor: colorScheme.error,
                                    ),
                                  );
                                }
                              });
                            },
                          );
                        }).toList().animate(interval: 50.ms).fadeIn().slideX(begin: 0.1),
                      ),
                    ).animate().fadeIn(delay: (index * 50).ms, duration: 300.ms).slideY(begin: 0.1);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Enviar Información'),
                  onPressed: () {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Información enviada (funcionalidad placeholder)'),
                          backgroundColor: colorScheme.secondaryContainer,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.secondary,
                    foregroundColor: colorScheme.onSecondary,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}