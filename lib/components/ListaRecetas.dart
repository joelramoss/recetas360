import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recetas360/components/DetalleReceta.dart';
import 'package:recetas360/components/Receta.dart';
import 'package:recetas360/components/editarReceta.dart';
import 'package:recetas360/pagines/InterfazAjustes.dart';
import 'package:recetas360/pagines/PantallacrearReceta.dart';
import 'package:recetas360/pagines/HistorialRecetas.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:recetas360/pagines/RecetasFavoritas.dart';
import 'package:shimmer/shimmer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Asegúrate de tener esta importación

// Current User's Login: joelramoss
// Current Date and Time (UTC - YYYY-MM-DD HH:MM:SS formatted): 2025-04-24 14:49:18

class ListaRecetas extends StatefulWidget {
  final String mainCategory;
  final String subCategory;

  const ListaRecetas({
    super.key,
    required this.mainCategory,
    required this.subCategory,
  });

  @override
  _ListaRecetasState createState() => _ListaRecetasState();
}

class _ListaRecetasState extends State<ListaRecetas> {
  // --- Helper: Shimmer Placeholder Card ---
  Widget _buildShimmerCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final shimmerBase = colorScheme.surfaceContainerHighest;
    final shimmerHighlight =
        colorScheme.surfaceContainerHighest.withOpacity(0.5);
    const double imageSize = 80.0;
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
              Container(
                width: imageSize,
                height: imageSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: internalPadding),
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
                .animate()
                .scale(
                    delay: 100.ms, duration: 400.ms, curve: Curves.elasticOut),
            const SizedBox(height: 16),
            Text(
              "No hay recetas en esta categoría aún.",
              style:
                  textTheme.titleMedium?.copyWith(color: colorScheme.secondary),
              textAlign: TextAlign.center,
            )
                .animate()
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
                .animate()
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
    print("Error loading recipes/favorites: $error");
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
              "Inténtalo de nuevo más tarde.",
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
                  foregroundColor: colorScheme.error),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Eliminar")),
        ],
      ),
    );
  }

  // --- Helper: Favorite Update (uses 'favoritos' subcollection) ---
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
        await favRef.set({'addedAt': FieldValue.serverTimestamp()});
      } else {
        await favRef.delete();
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
  Future<void> _deleteRecipe(BuildContext context, Receta receta) async {
    final colorScheme = Theme.of(context).colorScheme;
    final String recipeId = receta.id;
    final String imageUrl = receta.urlImagen;

    try {
      // 1. Eliminar el documento de Firestore
      await FirebaseFirestore.instance
          .collection('recetas')
          .doc(recipeId)
          .delete();

      // 2. Eliminar la imagen de Firebase Storage
      if (imageUrl.isNotEmpty) {
        try {
          Reference photoRef = FirebaseStorage.instance.refFromURL(imageUrl);
          await photoRef.delete();
          print("Imagen eliminada de Storage: $imageUrl");
        } catch (e) {
          print(
              "Error al eliminar imagen de Storage ($imageUrl): $e. Puede que necesites guardar la ruta de Storage en Firestore para una eliminación más fiable o que la URL no sea compatible con refFromURL.");
        }
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Receta eliminada.")));
    } catch (e) {
      print("Error deleting recipe document: $e");
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

  // --- Helper: Share Recipe ---
  Future<void> _shareRecipe(BuildContext context, Receta receta) async {
    final String recipeName = receta.nombre;
    final String recipeId = receta.id;
    // Ensure this is your desired deep link structure
    final String deepLinkUrl = "https://recetas360.com/receta?id=$recipeId";

    try {
      final DynamicLinkParameters parameters = DynamicLinkParameters(
        uriPrefix: 'https://recetas360.page.link', // Your Firebase Dynamic Links prefix
        link: Uri.parse(deepLinkUrl),
        androidParameters: const AndroidParameters(
          packageName: 'com.example.recetas360', // Your Android package name
          minimumVersion: 0,
        ),
        iosParameters: const IOSParameters(
          bundleId: 'com.example.recetas360', // Your iOS bundle ID
          minimumVersion: '0',
        ),
        socialMetaTagParameters: SocialMetaTagParameters(
          title: '¡Mira esta receta: $recipeName!',
          description: 'Descubre cómo preparar $recipeName en Recetas360.',
          imageUrl: Uri.tryParse(receta.urlImagen),
        ),
      );
      final ShortDynamicLink shortLink =
          await FirebaseDynamicLinks.instance.buildShortLink(parameters);
      final Uri shortUrl = shortLink.shortUrl;
      Share.share(
        '¡Echa un vistazo a esta receta: $recipeName! ${shortUrl.toString()}',
        subject: 'Receta: $recipeName',
      );
    } catch (e) {
      print("Error al crear el enlace dinámico: $e");
      // Fallback to simple text share
      final String shareText =
          "¡Mira esta deliciosa receta: $recipeName!\n\n"
          "Tiempo: ${receta.tiempoMinutos} min\n"
          "Calificación: ${receta.calificacion} estrellas\n\n"
          "Encuéntrala en Recetas360 (o tu app)."; // Generic app mention
      Share.share(shareText, subject: 'Receta: $recipeName');
    }
  }


  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    const double cardPadding = 16.0;
    const double starSize = 18.0;
    const double imageSize = 80.0;

    final userId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: userId != null
          ? FirebaseFirestore.instance
              .collection('usuarios')
              .doc(userId)
              .collection('favoritos')
              .snapshots()
          : Stream<QuerySnapshot<Map<String, dynamic>>>.value(
              QuerySnapshotData([], {})), // Empty snapshot for logged-out users
      builder: (context, favoritesSnapshot) {
        if (userId != null &&
            favoritesSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: _buildAppBar(context, textTheme),
            body: ListView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: cardPadding, vertical: cardPadding),
              itemCount: 5,
              itemBuilder: (context, index) => _buildShimmerCard(context),
            ),
          );
        }
        if (favoritesSnapshot.hasError) {
          return Scaffold(
            appBar: _buildAppBar(context, textTheme),
            body: _buildErrorState(context, favoritesSnapshot.error),
          );
        }

        final Set<String> favoriteIds =
            userId == null || !favoritesSnapshot.hasData
                ? <String>{}
                : favoritesSnapshot.data!.docs.map((doc) => doc.id).toSet();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('recetas')
              .where('categoria', isEqualTo: widget.mainCategory)
              .where('gastronomia', isEqualTo: widget.subCategory)
              .snapshots(),
          builder: (context, recipeSnapshot) {
            Widget body;
            bool recipesExist = false;

            if (recipeSnapshot.connectionState == ConnectionState.waiting) {
              body = ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: cardPadding, vertical: cardPadding),
                itemCount: 5,
                itemBuilder: (context, index) => _buildShimmerCard(context),
              );
            } else if (recipeSnapshot.hasError) {
              body = _buildErrorState(context, recipeSnapshot.error);
            } else if (!recipeSnapshot.hasData ||
                recipeSnapshot.data!.docs.isEmpty) {
              body = _buildEmptyState(context);
            } else {
              recipesExist = true;
              final recetasDocs = recipeSnapshot.data!.docs;
              body = ListView.builder(
                padding: EdgeInsets.only(
                  left: cardPadding,
                  right: cardPadding,
                  top: cardPadding,
                  bottom: cardPadding + (recipesExist ? 72 : 0), // Space for FAB
                ),
                itemCount: recetasDocs.length,
                itemBuilder: (context, index) {
                  final doc = recetasDocs[index];
                  final data = doc.data() as Map<String, dynamic>?;

                  if (data == null ||
                      data['nombre'] == null ||
                      data['urlImagen'] == null) {
                    return const SizedBox.shrink(); // Skip invalid item
                  }

                  final receta = Receta.fromFirestore(data, doc.id);
                  final bool isFavorite = favoriteIds.contains(receta.id);

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
                            // Action Icons Column
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min, // Important for Row layout
                              children: [
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
                                  visualDensity: VisualDensity.compact,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_note_rounded),
                                  color: colorScheme.secondary,
                                  tooltip: "Editar",
                                  onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              EditarReceta(receta: receta))),
                                  visualDensity: VisualDensity.compact,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.share_rounded),
                                  color: colorScheme.tertiary,
                                  tooltip: "Compartir receta",
                                  onPressed: () => _shareRecipe(context, receta),
                                  visualDensity: VisualDensity.compact,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_forever_rounded),
                                  color: colorScheme.error,
                                  tooltip: "Eliminar",
                                  onPressed: () async {
                                    final confirm =
                                        await _showDeleteConfirmationDialog(
                                            context);
                                    if (confirm == true) {
                                      _deleteRecipe(context, receta);
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
                },
              );
            }

            return Scaffold(
              appBar: _buildAppBar(context, textTheme),
              body: body,
              floatingActionButton: recipesExist
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
          },
        );
      },
    );
  }

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
        // Consider adding CarritoRestante if needed in this screen's AppBar
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
        metadata = const SnapshotMetadataData(false, false),
        size = docs.length;
}

class SnapshotMetadataData implements SnapshotMetadata {
  @override
  final bool hasPendingWrites;
  @override
  final bool isFromCache;

  const SnapshotMetadataData(this.hasPendingWrites, this.isFromCache);
}
