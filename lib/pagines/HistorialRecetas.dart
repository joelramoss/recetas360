import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recetas360/components/DetalleReceta.dart';
import 'package:recetas360/components/Receta.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:intl/date_symbol_data_local.dart'; // Import for initializeDateFormatting
import 'package:flutter_animate/flutter_animate.dart'; // Import animate

// Current User's Login: joelramoss
// Current Date and Time (UTC - YYYY-MM-DD HH:MM:SS formatted): 2025-04-24 14:45:14

class HistorialRecetas extends StatefulWidget {
  const HistorialRecetas({super.key});

  @override
  _HistorialRecetasState createState() => _HistorialRecetasState();
}

// Helper class for aggregated recipe data
class AggregatedCompletedRecipe {
  final String recetaId;
  final String nombreReceta;
  final String categoria;
  final String gastronomia;
  Timestamp latestTimestamp; // Puede cambiar si se encuentra una más reciente
  int completionCount;
  List<Timestamp> allCompletionTimestamps; // Nueva lista para todas las fechas

  AggregatedCompletedRecipe({
    required this.recetaId,
    required this.nombreReceta,
    required this.categoria,
    required this.gastronomia,
    required this.latestTimestamp,
    this.completionCount = 0,
    List<Timestamp>? allTimestamps, // Parámetro opcional para el constructor
  }) : allCompletionTimestamps = allTimestamps ?? []; // Inicializar la lista
}

class _HistorialRecetasState extends State<HistorialRecetas> {
  // Date formatter
  DateFormat? _dateFormatter;
  bool _isDateFormatterInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeDateFormatter();
  }

  Future<void> _initializeDateFormatter() async {
    try {
      await initializeDateFormatting('es_ES', null);
      if (mounted) {
        setState(() {
          _dateFormatter = DateFormat('dd/MM/yyyy HH:mm', 'es_ES');
          _isDateFormatterInitialized = true;
        });
      }
    } catch (e) {
      print("Error initializing date formatter: $e");
      if (mounted) {
        setState(() {
          _dateFormatter = DateFormat('dd/MM/yyyy HH:mm');
          _isDateFormatterInitialized = true;
        });
      }
    }
  }

  // Nueva función para filtrar recetas y verificar su existencia
  Future<Map<String, AggregatedCompletedRecipe>> _filterAndVerifyRecipes(
      Map<String, AggregatedCompletedRecipe> initialAggregatedRecipes) async {
    final Map<String, AggregatedCompletedRecipe> filteredMap = {};
    final List<Future<void>> verificationFutures = [];

    initialAggregatedRecipes.forEach((recetaId, aggRecipe) {
      verificationFutures.add(
        FirebaseFirestore.instance
            .collection('recetas')
            .doc(recetaId)
            .get()
            .then((recetaDoc) {
          if (recetaDoc.exists) {
            filteredMap[recetaId] = aggRecipe;
          } else {
            print("Historial: Receta con ID $recetaId no encontrada. No se mostrará.");
          }
        }).catchError((error) {
          print("Historial: Error al verificar receta $recetaId: $error. No se mostrará.");
          // Decide si quieres manejar el error de otra forma, por ahora se excluye.
        }),
      );
    });

    await Future.wait(verificationFutures); // Esperar a que todas las verificaciones terminen
    return filteredMap;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDateFormatterInitialized || _dateFormatter == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Historial de Recetas')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Historial')),
        body: const Center(child: Text("Inicia sesión para ver tu historial.")),
      );
    }
    final String userId = currentUser.uid;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Recetas'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('recetas_completadas')
            .where('usuario_id', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshotCompletadas) {
          if (snapshotCompletadas.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshotCompletadas.hasError) {
            print("Error loading history: ${snapshotCompletadas.error}");
            return Center(
              child: Text(
                "Error al cargar el historial.",
                style: textTheme.bodyLarge?.copyWith(color: colorScheme.error),
              ),
            );
          }
          if (!snapshotCompletadas.hasData || snapshotCompletadas.data!.docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_toggle_off_rounded, size: 60, color: colorScheme.secondary),
                    const SizedBox(height: 16),
                    Text(
                      "Aún no has completado ninguna receta",
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium?.copyWith(color: colorScheme.secondary),
                    ),
                  ],
                ),
              ),
            );
          }

          final Map<String, AggregatedCompletedRecipe> initialAggregatedRecipesMap = {};
          for (final doc in snapshotCompletadas.data!.docs) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) continue;

            final recetaId = data['receta_id'] as String?;
            if (recetaId == null) continue;

            final timestamp = (data['timestamp'] as Timestamp?) ?? (data['fecha_completado'] as Timestamp?);
            if (timestamp == null) continue;

            if (initialAggregatedRecipesMap.containsKey(recetaId)) {
              final existingEntry = initialAggregatedRecipesMap[recetaId]!;
              existingEntry.completionCount++;
              existingEntry.allCompletionTimestamps.add(timestamp); 
              if (timestamp.compareTo(existingEntry.latestTimestamp) > 0) {
                existingEntry.latestTimestamp = timestamp; 
              }
            } else {
              initialAggregatedRecipesMap[recetaId] = AggregatedCompletedRecipe(
                recetaId: recetaId,
                nombreReceta: data['nombre'] as String? ?? 'Receta sin nombre',
                categoria: data['categoria'] as String? ?? 'Sin categoría',
                gastronomia: data['gastronomia'] as String? ?? 'Otra',
                latestTimestamp: timestamp,
                completionCount: 1,
                allTimestamps: [timestamp], 
              );
            }
          }
          
          initialAggregatedRecipesMap.values.forEach((recipe) {
            recipe.allCompletionTimestamps.sort((a, b) => b.compareTo(a));
          });

          // Usar FutureBuilder para el proceso de filtrado
          return FutureBuilder<Map<String, AggregatedCompletedRecipe>>(
            future: _filterAndVerifyRecipes(initialAggregatedRecipesMap),
            builder: (context, snapshotFiltradas) {
              if (snapshotFiltradas.connectionState == ConnectionState.waiting) {
                return const Center(child: Text("Verificando recetas del historial..."));
              }
              if (snapshotFiltradas.hasError) {
                print("Error filtering/verifying recipes: ${snapshotFiltradas.error}");
                return Center(
                  child: Text(
                    "Error al verificar las recetas del historial.",
                    style: textTheme.bodyLarge?.copyWith(color: colorScheme.error),
                  ),
                );
              }
              if (!snapshotFiltradas.hasData || snapshotFiltradas.data!.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_toggle_off_rounded, size: 60, color: colorScheme.secondary),
                        const SizedBox(height: 16),
                        Text(
                          "No hay recetas completadas válidas en tu historial.",
                          textAlign: TextAlign.center,
                          style: textTheme.titleMedium?.copyWith(color: colorScheme.secondary),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final Map<String, AggregatedCompletedRecipe> filteredAggregatedRecipesMap = snapshotFiltradas.data!;
              
              // Nueva estructura de agrupación:
              // 1. Por Categoría
              // 2. Dentro de cada Categoría, por Gastronomía
              final Map<String, Map<String, List<AggregatedCompletedRecipe>>> recetasPorCategoriaLuegoGastronomia = {};
              for (final aggRecipe in filteredAggregatedRecipesMap.values) {
                recetasPorCategoriaLuegoGastronomia
                    .putIfAbsent(aggRecipe.categoria, () => {})
                    .putIfAbsent(aggRecipe.gastronomia, () => [])
                    .add(aggRecipe);
              }

              // Ordenación:
              // 1. Categorías alfabéticamente
              final sortedCategoriaKeys = recetasPorCategoriaLuegoGastronomia.keys.toList()..sort();

              // 2. Para cada categoría, Gastronomías alfabéticamente
              // 3. Para cada lista de recetas (dentro de categoría/gastronomía), por latestTimestamp (más reciente primero)
              for (final categoriaKey in sortedCategoriaKeys) {
                final gastronomiasMap = recetasPorCategoriaLuegoGastronomia[categoriaKey]!;
                final sortedGastronomiaKeysInternas = gastronomiasMap.keys.toList()..sort();
                
                Map<String, List<AggregatedCompletedRecipe>> sortedGastronomiasMapParaCategoria = {};
                for(var gKey in sortedGastronomiaKeysInternas) {
                    final recetas = gastronomiasMap[gKey]!;
                    recetas.sort((a, b) => b.latestTimestamp.compareTo(a.latestTimestamp)); // Ordenar recetas por fecha
                    sortedGastronomiasMapParaCategoria[gKey] = recetas;
                }
                recetasPorCategoriaLuegoGastronomia[categoriaKey] = sortedGastronomiasMapParaCategoria;
              }
              
              if (sortedCategoriaKeys.isEmpty) {
                 return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_toggle_off_rounded, size: 60, color: colorScheme.secondary),
                        const SizedBox(height: 16),
                        Text(
                          "No hay recetas completadas válidas en tu historial.",
                          textAlign: TextAlign.center,
                          style: textTheme.titleMedium?.copyWith(color: colorScheme.secondary),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sortedCategoriaKeys.length,
                itemBuilder: (context, categoriaIndex) {
                  final categoria = sortedCategoriaKeys[categoriaIndex];
                  final gastronomiasMap = recetasPorCategoriaLuegoGastronomia[categoria]!;
                  final sortedGastronomiaKeysInternas = gastronomiasMap.keys.toList(); // Ya están ordenadas

                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    clipBehavior: Clip.antiAlias,
                    child: ExpansionTile( // ExpansionTile para la Categoría
                      backgroundColor: colorScheme.surfaceContainerLowest,
                      shape: const Border(), 
                      collapsedShape: const Border(),
                      title: Text(
                        categoria,
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      children: sortedGastronomiaKeysInternas.map((gastronomiaKey) {
                        final recetasAgregadas = gastronomiasMap[gastronomiaKey]!;
                        
                        return ExpansionTile( // ExpansionTile para la Gastronomía
                          tilePadding: const EdgeInsets.only(left: 24, right: 16.0), // Indentación para subnivel
                          title: Text(
                            gastronomiaKey,
                            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          children: recetasAgregadas.map((aggRecipe) {
                            final fechaOriginalUltima = aggRecipe.latestTimestamp.toDate();
                            final fechaAjustadaUltima = fechaOriginalUltima.add(const Duration(hours: 2));
                            final ultimaFechaFormateada = _dateFormatter!.format(fechaAjustadaUltima);
                            final countText = aggRecipe.completionCount > 1 ? " (x${aggRecipe.completionCount})" : "";

                            Widget tileContent = ListTile(
                              contentPadding: const EdgeInsets.only(left: 32, right: 8, top: 4, bottom: 4), // Mayor indentación
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: colorScheme.primaryContainer,
                                foregroundColor: colorScheme.onPrimaryContainer,
                                child: Icon(_getCategoryIcon(aggRecipe.categoria), size: 18),
                              ),
                              title: Text("${aggRecipe.nombreReceta}$countText", style: textTheme.bodyLarge),
                              subtitle: Text(
                                'Última vez: $ultimaFechaFormateada', 
                                style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                              ),
                              onTap: () async {
                                try {
                                   final recetaDoc = await FirebaseFirestore.instance
                                    .collection('recetas')
                                    .doc(aggRecipe.recetaId)
                                    .get();

                                  if (!mounted) return;

                                  if (recetaDoc.exists) {
                                    final recetaData = recetaDoc.data()!;
                                    recetaData['id'] = recetaDoc.id; 
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
                                        content: Text('Esta receta ya no está disponible.', style: TextStyle(color: colorScheme.onError)),
                                        backgroundColor: colorScheme.error,
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                } catch (error) {
                                  if (!mounted) return;
                                  print("Error fetching recipe details on tap: $error");
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error al cargar detalles de la receta.', style: TextStyle(color: colorScheme.onError)),
                                      backgroundColor: colorScheme.error,
                                    ),
                                  );
                                }
                              },
                            );

                            if (aggRecipe.completionCount > 1) {
                              return ExpansionTile(
                                tilePadding: EdgeInsets.zero, 
                                leading: null, 
                                title: tileContent,
                                backgroundColor: colorScheme.surfaceContainerLowest.withOpacity(0.5),
                                childrenPadding: const EdgeInsets.only(left: 48, right: 16, bottom: 8, top:4), // Mayor indentación
                                children: aggRecipe.allCompletionTimestamps.map((timestamp) {
                                  final fechaOriginalItem = timestamp.toDate();
                                  final fechaAjustadaItem = fechaOriginalItem.add(const Duration(hours: 2));
                                  return ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.check_circle_outline, size: 16),
                                    title: Text(_dateFormatter!.format(fechaAjustadaItem), style: textTheme.bodySmall),
                                  );
                                }).toList(),
                              );
                            } else {
                              return tileContent;
                            }
                          }).toList(),
                        );
                      }).toList(),
                    ),
                  ).animate().fadeIn(delay: (100 * categoriaIndex).ms);
                },
              );
            },
          );
        },
      ),
    );
  }

  IconData _getCategoryIcon(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'carne': return Icons.kebab_dining_rounded;
      case 'pescado': return Icons.set_meal_rounded;
      case 'verduras': return Icons.grass_rounded;
      case 'lacteos': return Icons.icecream_rounded;
      case 'cereales': return Icons.breakfast_dining_rounded;
      case 'postre': return Icons.cake_rounded;
      case 'bebida': return Icons.local_bar_rounded;
      case 'pasta': return Icons.ramen_dining_rounded;
      case 'desayuno': return Icons.free_breakfast_rounded;
      default: return Icons.restaurant_rounded;
    }
  }
}