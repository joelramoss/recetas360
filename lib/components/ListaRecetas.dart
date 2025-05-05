import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recetas360/components/DetalleReceta.dart';
import 'package:recetas360/components/Receta.dart';
import 'package:recetas360/components/editarReceta.dart'; // Ensure this import is correct
import 'package:recetas360/pagines/InterfazAjustes.dart'; // Ensure this import is correct
import 'package:recetas360/pagines/PantallacrearReceta.dart'; // Ensure this import is correct
import 'package:recetas360/pagines/HistorialRecetas.dart'; // Ensure this import is correct
import 'package:flutter_animate/flutter_animate.dart'; // Import flutter_animate
import 'package:recetas360/pagines/RecetasFavoritas.dart';
import 'package:shimmer/shimmer.dart'; // Import shimmer

// Current User's Login: joelramoss
// Current Date and Time (UTC - YYYY-MM-DD HH:MM:SS formatted): 2025-04-24 14:49:18

class ListaRecetas extends StatefulWidget {
  final String mainCategory;
  final String subCategory;

  const ListaRecetas({
    Key? key,
    required this.mainCategory,
    required this.subCategory,
  }) : super(key: key);

  @override
  _ListaRecetasState createState() => _ListaRecetasState();
}

class _ListaRecetasState extends State<ListaRecetas> {
  // --- Helper: Shimmer Placeholder Card ---
  Widget _buildShimmerCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final shimmerBase =
        colorScheme.surfaceContainerHighest; // Use a subtle base
    final shimmerHighlight = colorScheme.surfaceContainerHighest
        .withOpacity(0.5); // More subtle highlight
    const double imageSize = 80.0; // Consistent size
    const double cardPadding = 12.0;
    const double internalPadding = 16.0;

    return Shimmer.fromColors(
      baseColor: shimmerBase,
      highlightColor: shimmerHighlight,
      child: Card(
        elevation: 1,
        margin: const EdgeInsets.only(bottom: 16.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(cardPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Placeholder
              Container(
                width: imageSize,
                height: imageSize,
                decoration: BoxDecoration(
                  color: Colors.white, // Must be non-transparent for shimmer
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: internalPadding),
              // Text Placeholders
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        height: 16,
                        width: double.infinity,
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 8)),
                    Container(
                        height: 14,
                        width: 100,
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 8)),
                    Container(height: 14, width: 150, color: Colors.white),
                  ],
                ),
              ),
              // Icon Placeholders (Simpler: just one placeholder block)
              Container(
                  width: 24,
                  height: 80,
                  color: Colors.white,
                  margin: const EdgeInsets.only(left: 8)),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper: Empty State Widget ---
  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.ramen_dining_outlined,
                    size: 60, color: colorScheme.secondary)
                .animate() // Animate the icon
                .scale(
                    delay: 100.ms, duration: 400.ms, curve: Curves.elasticOut),
            const SizedBox(height: 16),
            Text(
              "No hay recetas en esta categoría aún.",
              style:
                  textTheme.titleMedium?.copyWith(color: colorScheme.secondary),
              textAlign: TextAlign.center,
            )
                .animate() // Animate the text
                .fadeIn(delay: 200.ms, duration: 400.ms)
                .slideY(
                    begin: 0.2,
                    delay: 200.ms,
                    duration: 400.ms,
                    curve: Curves.easeOut),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CrearRecetaScreen())),
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const Text("Crear la Primera Receta"),
            )
                .animate() // Animate the button
                .fadeIn(delay: 300.ms, duration: 400.ms)
                .slideY(
                    begin: 0.5,
                    delay: 300.ms,
                    duration: 400.ms,
                    curve: Curves.easeOut),
          ],
        ),
      ),
    );
  }

  // --- Helper: Error State Widget ---
  Widget _buildErrorState(BuildContext context, Object? error) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    print("Error loading recipes/favorites: $error"); // Log error
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 60, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              "Error al cargar las recetas.",
              style: textTheme.titleMedium?.copyWith(color: colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Inténtalo de nuevo más tarde.", // Simple user message
              style: textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onErrorContainer),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper: Delete Confirmation Dialog ---
  Future<bool?> _showDeleteConfirmationDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar Receta"),
        content: const Text("¿Estás seguro? Esta acción no se puede deshacer."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancelar")),
          TextButton(
              style: TextButton.styleFrom(
                  foregroundColor:
                      colorScheme.error), // Error color for delete action
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Eliminar")),
        ],
      ),
    );
  }

  // --- Helper: Favorite Update ---
  Future<void> _updateFavorite(BuildContext context, String userId,
      String recipeId, bool isCurrentlyFavorite) async {
    final colorScheme = Theme.of(context).colorScheme;
    final favRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .collection('favoritos')
        .doc(recipeId);
    try {
      if (!isCurrentlyFavorite) {
        // Add to favorites
        await favRef.set({'addedAt': FieldValue.serverTimestamp()});
        // Optional: Show confirmation SnackBar
        // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Añadido a favoritos")));
      } else {
        // Remove from favorites
        await favRef.delete();
        // Optional: Show confirmation SnackBar
        // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Quitado de favoritos")));
      }
    } catch (e) {
      print("Error updating favorite: $e");
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al guardar favorito.",
              style: TextStyle(color: colorScheme.onError)),
          backgroundColor: colorScheme.error,
        ),
      );
    }
  }

  // --- Helper: Delete Recipe ---
  Future<void> _deleteRecipe(BuildContext context, String recipeId) async {
    final colorScheme = Theme.of(context).colorScheme;
    try {
      await FirebaseFirestore.instance
          .collection('recetas')
          .doc(recipeId)
          .delete();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Receta eliminada.")));
      // Note: The StreamBuilder will automatically remove the item from the list.
    } catch (e) {
      print("Error deleting recipe: $e");
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al eliminar la receta.",
              style: TextStyle(color: colorScheme.onError)),
          backgroundColor: colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    const double cardPadding = 16.0;
    const double starSize = 18.0;

    final userId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      // Outer Stream: Favorites
      stream: userId != null
          ? FirebaseFirestore.instance
              .collection('usuarios')
              .doc(userId)
              .collection('favoritos')
              .snapshots()
          : Stream<QuerySnapshot<Map<String, dynamic>>>.value(
              QuerySnapshotData([], {})),
      builder: (context, favoritesSnapshot) {
        // Handle favorite stream state
        if (userId != null &&
            favoritesSnapshot.connectionState == ConnectionState.waiting) {
          // Show a basic loading Scaffold while favorites load initially
          return Scaffold(
            appBar: _buildAppBar(context, textTheme), // Use helper for AppBar
            body: ListView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: cardPadding, vertical: cardPadding),
              itemCount: 5,
              itemBuilder: (context, index) => _buildShimmerCard(context),
            ),
          );
        }
        if (favoritesSnapshot.hasError) {
          // Show error Scaffold if favorites fail
          return Scaffold(
            appBar: _buildAppBar(context, textTheme),
            body: _buildErrorState(context, favoritesSnapshot.error),
          );
        }

        // Favorites loaded (or user not logged in)
        final Set<String> favoriteIds =
            userId == null || !favoritesSnapshot.hasData
                ? <String>{}
                : favoritesSnapshot.data!.docs.map((doc) => doc.id).toSet();

        // --- Inner Stream: Recipes ---
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('recetas')
              .where('categoria', isEqualTo: widget.mainCategory)
              .where('gastronomia', isEqualTo: widget.subCategory)
              .snapshots(),
          builder: (context, recipeSnapshot) {
            // --- Build the Scaffold INSIDE the recipe stream builder ---
            Widget body;
            bool recipesExist =
                false; // Determine existence based on this snapshot

            if (recipeSnapshot.connectionState == ConnectionState.waiting) {
              body = ListView.builder(
                // Shimmer for recipe loading
                padding: const EdgeInsets.symmetric(
                    horizontal: cardPadding, vertical: cardPadding),
                itemCount: 5,
                itemBuilder: (context, index) => _buildShimmerCard(context),
              );
              // Assume recipes might exist while loading, show FAB optimistically? Or hide? Let's hide for now.
              recipesExist = false; // Or keep false until data confirms
            } else if (recipeSnapshot.hasError) {
              body = _buildErrorState(context, recipeSnapshot.error);
              recipesExist = false;
            } else if (!recipeSnapshot.hasData ||
                recipeSnapshot.data!.docs.isEmpty) {
              body = _buildEmptyState(context); // Empty state
              recipesExist = false;
            } else {
              // Data loaded and not empty
              recipesExist = true;
              final recetasDocs = recipeSnapshot.data!.docs;
              body = ListView.builder(
                // Actual recipe list
                padding: const EdgeInsets.only(
                  left: cardPadding,
                  right: cardPadding,
                  top: cardPadding,
                  bottom: cardPadding +
                      72, // Add space for FAB (56 height + 16 margin)
                ),
                itemCount: recetasDocs.length,
                itemBuilder: (context, index) {
                  // --- Recipe Card Logic (remains the same) ---
                  final doc = recetasDocs[index];
                  final data = doc.data() as Map<String, dynamic>?;
                  if (data == null ||
                      data['nombre'] == null ||
                      data['urlImagen'] == null) {
                    return const SizedBox.shrink();
                  }
                  final receta = Receta.fromFirestore(data, doc.id);
                  final bool isFavorite = favoriteIds.contains(receta.id);
                  const double imageSize = 80.0;

                  return GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => DetalleReceta(receta: receta))),
                    child: Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: cardPadding),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image
                            Hero(
                              tag: 'recipe_image_${receta.id}',
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  receta.urlImagen,
                                  width: imageSize,
                                  height: imageSize,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    width: imageSize,
                                    height: imageSize,
                                    decoration: BoxDecoration(
                                        color:
                                            colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(8)),
                                    child: Icon(Icons.broken_image_outlined,
                                        color: colorScheme.onSurfaceVariant,
                                        size: 32),
                                  ),
                                  loadingBuilder: (context, child,
                                          loadingProgress) =>
                                      loadingProgress == null
                                          ? child
                                          : SizedBox(
                                              width: imageSize,
                                              height: imageSize,
                                              child: Shimmer.fromColors(
                                                baseColor: colorScheme
                                                    .surfaceContainerHighest,
                                                highlightColor: colorScheme
                                                    .surfaceContainerHighest
                                                    .withOpacity(0.5),
                                                child: Container(
                                                    decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8))),
                                              ),
                                            ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Text Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(receta.nombre,
                                      style: textTheme.titleMedium,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text("Tiempo: ${receta.tiempoMinutos} min",
                                      style: textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurfaceVariant)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: List.generate(
                                        5,
                                        (i) => Icon(
                                              i < receta.calificacion
                                                  ? Icons.star_rounded
                                                  : Icons.star_border_rounded,
                                              color: colorScheme.primary,
                                              size: starSize,
                                            )),
                                  ),
                                ],
                              ),
                            ),
                            // Action Icons
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                // Favorite
                                IconButton(
                                  icon: Icon(isFavorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded),
                                  color: isFavorite
                                      ? colorScheme.primary
                                      : colorScheme.outline,
                                  tooltip: isFavorite
                                      ? "Quitar favorito"
                                      : "Añadir favorito",
                                  onPressed: userId == null
                                      ? null
                                      : () => _updateFavorite(context, userId,
                                          receta.id, isFavorite),
                                  visualDensity: VisualDensity
                                      .compact, // Make icons tighter
                                ),
                                // Edit
                                IconButton(
                                  icon: const Icon(Icons
                                      .edit_note_rounded), // Example rounded icon
                                  color: colorScheme.secondary,
                                  tooltip: "Editar",
                                  onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              EditarReceta(receta: receta))),
                                  visualDensity: VisualDensity.compact,
                                ),
                                // Delete
                                IconButton(
                                  icon: const Icon(Icons
                                      .delete_forever_rounded), // Example rounded icon
                                  color: colorScheme.error,
                                  tooltip: "Eliminar",
                                  onPressed: () async {
                                    final confirm =
                                        await _showDeleteConfirmationDialog(
                                            context);
                                    if (confirm == true) {
                                      _deleteRecipe(context, receta.id);
                                    }
                                  },
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: (50 * (index % 10)).ms)
                      .slideY(
                          begin: 0.1,
                          duration: 300.ms,
                          delay: (50 * (index % 10)).ms,
                          curve: Curves.easeOut);
                  // --- End Recipe Card Logic ---
                },
              );
            }

            // --- Return the Scaffold ---
            return Scaffold(
              appBar: _buildAppBar(context, textTheme), // Use helper
              body: body, // Use the determined body widget
              floatingActionButton: recipesExist // Conditionally show FAB
                  ? FloatingActionButton.extended(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CrearRecetaScreen())),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text("Crear Receta"),
                    ).animate().slideY(
                      begin: 2,
                      delay: 500.ms,
                      duration: 500.ms,
                      curve: Curves.easeOut)
                  : null,
            );
            // --- End Returning Scaffold ---
          },
        );
        // --- End Inner Stream ---
      },
    );
    // --- End Outer Stream ---
  }

  // --- Helper to build AppBar (to avoid repetition) ---
  AppBar _buildAppBar(BuildContext context, TextTheme textTheme) {
    return AppBar(
      title: Text("${widget.mainCategory} / ${widget.subCategory}",
          style: textTheme.titleMedium),
      actions: [
        IconButton(
            icon: const Icon(Icons.favorite_border_outlined),
            tooltip: "Favoritos",
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const RecetasFavoritas()))),
        IconButton(
          icon: const Icon(Icons.history_rounded),
          tooltip: "Historial",
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const HistorialRecetas())),
        ),
        IconButton(
          icon: const Icon(Icons.settings_rounded),
          tooltip: "Ajustes",
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const PaginaAjustes())),
        ),
      ],
    );
  }
}

// Helper class for QuerySnapshot.empty() with correct type
class QuerySnapshotData<T extends Object?> implements QuerySnapshot<T> {
  @override
  final List<QueryDocumentSnapshot<T>> docs;

  @override
  final List<DocumentChange<T>> docChanges;

  @override
  final SnapshotMetadata metadata;

  @override
  final int size;

  QuerySnapshotData(this.docs, Map<String, dynamic> metadataMap)
      : docChanges = const [],
        metadata = const SnapshotMetadataData(false, false), // Example metadata
        size = docs.length;
}

class SnapshotMetadataData implements SnapshotMetadata {
  @override
  final bool hasPendingWrites;

  @override
  final bool isFromCache;

  const SnapshotMetadataData(this.hasPendingWrites, this.isFromCache);
}
