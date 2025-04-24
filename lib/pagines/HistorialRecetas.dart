import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recetas360/components/DetalleReceta.dart';
import 'package:recetas360/components/Receta.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:flutter_animate/flutter_animate.dart'; // Import animate

// Current User's Login: joelramoss
// Current Date and Time (UTC - YYYY-MM-DD HH:MM:SS formatted): 2025-04-24 14:45:14

class HistorialRecetas extends StatefulWidget {
  const HistorialRecetas({Key? key}) : super(key: key);

  @override
  _HistorialRecetasState createState() => _HistorialRecetasState();
}

class _HistorialRecetasState extends State<HistorialRecetas> {
  // Date formatter
  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    // Handle case where user might not be logged in
    if (currentUser == null) {
      // Optionally navigate to login or show a specific message
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
        // backgroundColor: colorScheme.surface, // Uses theme default
        title: const Text('Historial de Recetas'),
      ),
      // Removed Container with gradient
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('recetas_completadas')
            .where('usuario_id', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          // --- Loading State ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator()); // Themed indicator
          }

          // --- Error State ---
          if (snapshot.hasError) {
             print("Error loading history: ${snapshot.error}");
             return Center(
               child: Text(
                 "Error al cargar el historial.",
                 style: textTheme.bodyLarge?.copyWith(color: colorScheme.error),
               ),
             );
          }

          // --- Empty State ---
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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

          // --- Data State ---
          // Sort locally by timestamp (descending)
          final docs = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final aData = a.data() as Map<String, dynamic>?;
              final bData = b.data() as Map<String, dynamic>?;
              // Handle potential null data or timestamp
              final Timestamp? aTime = aData?['timestamp'] as Timestamp?;
              final Timestamp? bTime = bData?['timestamp'] as Timestamp?;
              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1; // Nulls last
              if (bTime == null) return -1; // Nulls last
              return bTime.compareTo(aTime); // Most recent first
            });

          // Group documents by gastronomy
          final Map<String, List<DocumentSnapshot>> recetasPorGastronomia = {};
          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) continue; // Skip if data is null
            final gastronomia = data['gastronomia'] as String? ?? 'Otra'; // Default group

            recetasPorGastronomia.putIfAbsent(gastronomia, () => []).add(doc);
          }

          // Build list grouped by gastronomy
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: recetasPorGastronomia.length,
            itemBuilder: (context, index) {
              final gastronomia = recetasPorGastronomia.keys.toList()[index];
              final recetas = recetasPorGastronomia[gastronomia]!;

              // Use Card for each gastronomy group
              return Card(
                elevation: 1, // Subtle elevation
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                clipBehavior: Clip.antiAlias, // Clip content to shape
                child: ExpansionTile(
                  // Themed ExpansionTile
                  shape: const Border(), // Remove default border when expanded
                  collapsedShape: const Border(), // Remove default border when collapsed
                  backgroundColor: colorScheme.surfaceContainerLowest, // Background when expanded
                  title: Text(
                    gastronomia,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  // childrenPadding: const EdgeInsets.only(bottom: 8), // Add padding below children
                  children: recetas.map((doc) {
                    final data = doc.data() as Map<String, dynamic>?;
                    if (data == null) return const SizedBox.shrink(); // Skip rendering if data is null

                    // Use 'timestamp' field if 'fecha_completado' is not reliable
                    final fecha = (data['timestamp'] as Timestamp?)?.toDate() ??
                                  (data['fecha_completado'] as Timestamp?)?.toDate();
                    final fechaFormateada = fecha != null ? _dateFormatter.format(fecha) : "Fecha desconocida";
                    final categoria = data['categoria'] as String? ?? 'Sin categoría';
                    final nombreReceta = data['nombre'] as String? ?? 'Receta sin nombre';
                    final recetaId = data['receta_id'] as String?;

                    // Themed ListTile
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.primaryContainer,
                        foregroundColor: colorScheme.onPrimaryContainer,
                        child: Icon(_getCategoryIcon(categoria), size: 20),
                      ),
                      title: Text(nombreReceta, style: textTheme.bodyLarge),
                      subtitle: Text(
                        '$categoria • $fechaFormateada',
                        style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                      onTap: recetaId == null ? null : () { // Disable onTap if recetaId is missing
                        FirebaseFirestore.instance
                            .collection('recetas')
                            .doc(recetaId)
                            .get()
                            .then((recetaDoc) {
                          if (!mounted) return; // Check if widget is still mounted

                          if (recetaDoc.exists) {
                            final recetaData = recetaDoc.data()!;
                            recetaData['id'] = recetaDoc.id; // Ensure ID is added

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
                              ),
                            );
                          }
                        }).catchError((error) {
                           if (!mounted) return;
                           print("Error fetching recipe details: $error");
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error al cargar detalles de la receta.', style: TextStyle(color: colorScheme.onError)),
                                backgroundColor: colorScheme.error,
                              ),
                            );
                        });
                      },
                    );
                  }).toList(),
                ),
              ).animate().fadeIn(delay: (100 * index).ms); // Animate card entrance
            },
          );
        },
      ),
    );
  }

  // Helper function for category icons (remains the same)
  IconData _getCategoryIcon(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'carne': return Icons.kebab_dining_rounded; // Example alternative
      case 'pescado': return Icons.set_meal_rounded;
      case 'verduras': return Icons.grass_rounded; // Example alternative
      case 'lacteos': return Icons.icecream_rounded; // Example alternative
      case 'cereales': return Icons.breakfast_dining_rounded; // Example alternative
      case 'postre': return Icons.cake_rounded;
      case 'bebida': return Icons.local_bar_rounded;
      case 'pasta': return Icons.ramen_dining_rounded; // Example alternative
      case 'desayuno': return Icons.free_breakfast_rounded;
      default: return Icons.restaurant_rounded;
    }
  }
}