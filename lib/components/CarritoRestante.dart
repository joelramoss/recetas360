import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:recetas360/serveis/UsuarioUtil.dart';
import 'package:recetas360/components/Receta.dart';
import 'package:recetas360/components/DetalleReceta.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Definir una clase para el resultado del procesamiento
class ProcesadoFaltantes {
  final List<DocumentSnapshot> docsValidos;
  final Map<String, ({Map<String, bool> ingredientes, String? nombreReceta})>
      datosMapa;
  ProcesadoFaltantes(this.docsValidos, this.datosMapa);
}

class CarritoFaltantes extends StatefulWidget {
  const CarritoFaltantes({Key? key}) : super(key: key);

  @override
  _CarritoFaltantesState createState() => _CarritoFaltantesState();
}

class _CarritoFaltantesState extends State<CarritoFaltantes> {
  final UsuarioUtil _usuarioUtil = UsuarioUtil();
  Map<String, ({Map<String, bool> ingredientes, String? nombreReceta})>
      _datosFaltantesPorReceta = {};

  @override
  void initState() {
    super.initState();
    // _datosFaltantesPorReceta se llenará dinámicamente
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

  Future<void> _actualizarIngrediente(
      String recetaId, String ingrediente, bool nuevoEstado) async {
    String? userId = _usuarioUtil.getUidUsuarioActual();
    if (userId == null) return;

    // Usar una copia local para la lógica de actualización, _datosFaltantesPorReceta se actualizará por el stream
    final Map<String, bool> ingredientesActuales =
        Map.from(_datosFaltantesPorReceta[recetaId]?.ingredientes ?? {});
    final String nombreRecetaActual =
        _datosFaltantesPorReceta[recetaId]?.nombreReceta ??
            'Receta Desconocida';

    ingredientesActuales[ingrediente] = nuevoEstado;

    final docRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .collection('recetas_faltantes')
        .doc(recetaId);

    try {
      if (nuevoEstado) {
        // Si se marca como faltante
        await docRef.set(
            {
              'ingredientes': {
                ingrediente: true
              }, // Solo el ingrediente que se marca como faltante
              'actualizadoEn': FieldValue.serverTimestamp(),
              'recetaNombre':
                  nombreRecetaActual, // Mantener el nombre de la receta
            },
            SetOptions(mergeFields: [
              'ingredientes.$ingrediente',
              'actualizadoEn',
              'recetaNombre'
            ]));
      } else {
        // Si se desmarca (ya no falta)
        await docRef.update({
          'ingredientes.$ingrediente': FieldValue.delete(),
          'actualizadoEn': FieldValue.serverTimestamp(),
        });

        // Verificar si quedan otros ingredientes faltantes en este documento
        final docSnapshot = await docRef.get();
        if (docSnapshot.exists) {
          final dataActual = docSnapshot.data();
          final ingredientesRestantes =
              Map<String, dynamic>.from(dataActual?['ingredientes'] ?? {});
          if (ingredientesRestantes.isEmpty) {
            // Si no quedan ingredientes en el mapa
            await docRef
                .delete(); // Eliminar el documento de la receta de la lista de faltantes
          }
        }
      }
    } catch (e) {
      print("Error al actualizar el ingrediente: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Error al actualizar ingrediente: ${e.toString()}')),
        );
      }
    }
  }

  // Función asíncrona para filtrar y preparar datos
  Future<ProcesadoFaltantes> _procesarYFiltrarRecetas(
      List<DocumentSnapshot> docsOriginalesFaltantes) async {
    List<DocumentSnapshot> recetasValidasParaMostrar = [];
    Map<String, ({Map<String, bool> ingredientes, String? nombreReceta})>
        datosFaltantesMapa = {};
    String? currentUserId = _usuarioUtil.getUidUsuarioActual();

    for (var docFaltante in docsOriginalesFaltantes) {
      final recetaId = docFaltante.id;
      final recetaPrincipalDoc = await FirebaseFirestore.instance
          .collection('recetas')
          .doc(recetaId)
          .get();

      if (recetaPrincipalDoc.exists) {
        final dataFaltante = docFaltante.data() as Map<String, dynamic>;
        final Map<String, dynamic> ingredientesRaw =
            dataFaltante['ingredientes'] as Map<String, dynamic>? ?? {};
        final Map<String, bool> ingredientesTyped = {};
        bool tieneFaltantesMarcadosComoTrue = false;

        ingredientesRaw.forEach((key, value) {
          if (value is bool) {
            ingredientesTyped[key] = value;
            if (value == true) {
              // Solo nos interesan los que están marcados como true (faltantes)
              tieneFaltantesMarcadosComoTrue = true;
            }
          } else {
            print(
                "ADVERTENCIA: Ingrediente '$key' para receta $recetaId no es booleano, es ${value.runtimeType}. Se omitirá.");
          }
        });

        if (tieneFaltantesMarcadosComoTrue) {
          recetasValidasParaMostrar.add(docFaltante);
          datosFaltantesMapa[recetaId] = (
            ingredientes: ingredientesTyped,
            nombreReceta: dataFaltante['recetaNombre'] as String? ??
                recetaPrincipalDoc.data()?['nombre'] as String? ??
                'Receta Desconocida'
          );
        }
      } else {
        // La receta principal no existe, eliminar la entrada de 'recetas_faltantes'
        if (currentUserId != null) {
          print(
              "Receta $recetaId no encontrada en 'recetas'. Eliminando de 'recetas_faltantes' para usuario $currentUserId.");
          FirebaseFirestore.instance
              .collection('usuarios')
              .doc(currentUserId)
              .collection('recetas_faltantes')
              .doc(recetaId)
              .delete()
              .catchError((e) => print(
                  "Error eliminando receta faltante huérfana $recetaId: $e"));
        }
      }
    }
    return ProcesadoFaltantes(recetasValidasParaMostrar, datosFaltantesMapa);
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
            padding:
                const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
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
              builder: (context, streamSnapshot) {
                if (streamSnapshot.connectionState == ConnectionState.waiting &&
                    _datosFaltantesPorReceta.isEmpty) {
                  // Mostrar carga solo si no hay datos previos
                  return Center(
                      child: CircularProgressIndicator(
                          color: colorScheme.primary));
                }

                if (streamSnapshot.hasError) {
                  print("Error en StreamBuilder: ${streamSnapshot.error}");
                  return Center(
                      child: Text("Error al cargar datos.",
                          style: textTheme.titleMedium));
                }

                // Usar los datos del stream si están disponibles, sino mantener los últimos datos válidos para evitar parpadeo
                final docsOriginales = streamSnapshot.data?.docs ?? [];

                return FutureBuilder<ProcesadoFaltantes>(
                  // Usar una key con los docs originales para re-ejecutar el future si cambian
                  key: ValueKey(docsOriginales
                      .map((d) =>
                          d.id + (d.data() as Map<String, dynamic>).toString())
                      .join()),
                  future: _procesarYFiltrarRecetas(docsOriginales),
                  builder: (context, filteredSnapshot) {
                    if (filteredSnapshot.connectionState ==
                            ConnectionState.waiting &&
                        _datosFaltantesPorReceta.isEmpty) {
                      return Center(
                          child: CircularProgressIndicator(
                              color: colorScheme.primary));
                    }

                    if (filteredSnapshot.hasError) {
                      print(
                          "Error en FutureBuilder de filtrado: ${filteredSnapshot.error}");
                      return Center(
                          child: Text("Error al procesar ingredientes.",
                              style: textTheme.titleMedium));
                    }

                    // Actualizar el estado _datosFaltantesPorReceta si el Future completó con nuevos datos
                    if (filteredSnapshot.connectionState ==
                            ConnectionState.done &&
                        filteredSnapshot.hasData) {
                      _datosFaltantesPorReceta =
                          filteredSnapshot.data!.datosMapa;
                    }

                    // Usar la lista de documentos válidos del snapshot del Future si está disponible,
                    // o una lista vacía si no, para evitar errores.
                    final List<DocumentSnapshot> recetasParaMostrar =
                        filteredSnapshot.data?.docsValidos ?? [];

                    if (recetasParaMostrar.isEmpty &&
                        filteredSnapshot.connectionState ==
                            ConnectionState.done) {
                      return Center(
                        child: Text(
                          "¡No te falta nada!",
                          style: textTheme.titleMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 100.ms),
                      );
                    }
                    if (recetasParaMostrar.isEmpty &&
                        filteredSnapshot.connectionState ==
                            ConnectionState.waiting) {
                      // Si está esperando y no hay nada que mostrar aún, puede ser el loader o nada si ya había datos
                      return _datosFaltantesPorReceta.isEmpty
                          ? Center(
                              child: CircularProgressIndicator(
                                  color: colorScheme.primary))
                          : _buildListView(
                              _datosFaltantesPorReceta.keys
                                  .map((id) {
                                    // Intenta construir con datos viejos si existen
                                    try {
                                      return docsOriginales
                                          .firstWhere((doc) => doc.id == id);
                                    } catch (_) {
                                      // If not found, firstWhere throws StateError
                                      return null;
                                    }
                                  })
                                  .whereType<DocumentSnapshot>()
                                  .toList(),
                              colorScheme,
                              textTheme);
                    }

                    return _buildListView(
                        recetasParaMostrar, colorScheme, textTheme);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<DocumentSnapshot> recetasAMostrar,
      ColorScheme colorScheme, TextTheme textTheme) {
    if (recetasAMostrar.isEmpty && _datosFaltantesPorReceta.isNotEmpty) {
      // Si recetasAMostrar está vacío pero _datosFaltantesPorReceta no,
      // significa que el Future aún no ha terminado o no devolvió nada,
      // pero tenemos datos antiguos. Intentamos construir con ellos.
      // Esto es para reducir el parpadeo.
      final docsParaReconstruir = _datosFaltantesPorReceta.keys
          .map((id) {
            // Necesitamos encontrar el DocumentSnapshot original para pasarlo al itemBuilder
            // Esto es un poco hacky y depende de que el stream original aún tenga esos docs.
            // Una mejor solución a largo plazo sería cachear los DocumentSnapshot junto con los datos procesados.
            // Por ahora, si no lo encontramos, lo omitimos.
            try {
              return (ModalRoute.of(context)?.settings.arguments
                      as Stream<QuerySnapshot>?)
                  ?.firstWhere((event) => event.docs.any((d) => d.id == id))
                  .then((event) => event.docs.firstWhere((d) => d.id == id))
                  .catchError((_) =>
                      null); // Esto es muy complejo y no funcionará bien.
            } catch (_) {
              return null;
            }
            return null; // Simplificación: si no hay docs nuevos, no mostramos nada o el loader
          })
          .whereType<DocumentSnapshot>()
          .toList();
      // Si no podemos reconstruir, mostramos loader o mensaje.
      // Esta lógica de reconstrucción con datos viejos es compleja y propensa a errores.
      // Es mejor confiar en el FutureBuilder y manejar sus estados.
    }

    // Si recetasAMostrar está vacío (y el Future ya terminó), el mensaje de "No te falta nada" se maneja arriba.
    // Si está esperando y recetasAMostrar está vacío, el loader se maneja arriba.

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: recetasAMostrar.length,
      itemBuilder: (context, index) {
        final doc = recetasAMostrar[index];
        final recetaId = doc.id;
        final datosRecetaFaltante = _datosFaltantesPorReceta[recetaId];

        if (datosRecetaFaltante == null) {
          // Esto no debería ocurrir si _datosFaltantesPorReceta se llena correctamente
          // desde el FutureBuilder
          return const SizedBox.shrink();
        }

        final ingredientes = datosRecetaFaltante.ingredientes;
        final nombreReceta =
            datosRecetaFaltante.nombreReceta ?? 'Receta sin nombre';

        // Filtrar solo los ingredientes marcados como true (faltantes) para este ExpansionTile
        final faltantesEnEsteTile = ingredientes.entries
            .where((entry) => entry.value == true)
            .map((entry) => entry.key)
            .toList();

        if (faltantesEnEsteTile.isEmpty) {
          // Si esta receta específica ya no tiene ingredientes faltantes (todos desmarcados)
          // no debería mostrarse. _procesarYFiltrarRecetas ya debería manejar esto.
          return const SizedBox.shrink();
        }

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
              nombreReceta,
              style:
                  textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            children: faltantesEnEsteTile
                .map((ingrediente) {
                  final esFaltante = ingredientes[ingrediente] ??
                      false; // Debería ser true aquí
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: esFaltante
                          ? colorScheme.errorContainer
                          : colorScheme
                              .primaryContainer, // No debería llegar a primaryContainer aquí
                      child: Icon(
                        esFaltante
                            ? Icons.remove_shopping_cart_outlined
                            : Icons.check_circle_outline_rounded,
                        color: esFaltante
                            ? colorScheme.onErrorContainer
                            : colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(ingrediente, style: textTheme.bodyLarge),
                    onTap: () {
                      _actualizarIngrediente(
                          recetaId, ingrediente, !esFaltante);
                    },
                    onLongPress: () {
                      FirebaseFirestore.instance
                          .collection('recetas')
                          .doc(recetaId) // Usar recetaId que es doc.id
                          .get()
                          .then((recetaDoc) {
                        if (recetaDoc.exists) {
                          final recetaData = recetaDoc.data()!;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetalleReceta(
                                receta: Receta.fromFirestore(
                                    recetaData, recetaDoc.id),
                              ),
                            ),
                          );
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Esta receta ya no está disponible',
                                    style:
                                        TextStyle(color: colorScheme.onError)),
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
                              content: Text('Error al cargar la receta',
                                  style: TextStyle(color: colorScheme.onError)),
                              backgroundColor: colorScheme.error,
                            ),
                          );
                        }
                      });
                    },
                  );
                })
                .toList()
                .animate(interval: 50.ms)
                .fadeIn()
                .slideX(begin: 0.1),
          ),
        )
            .animate()
            .fadeIn(delay: (index * 50).ms, duration: 300.ms)
            .slideY(begin: 0.1);
      },
    );
  }
}
