import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recetas360/components/DetalleReceta.dart';
import 'package:recetas360/components/Receta.dart';
import 'package:recetas360/pagines/InterfazAjustes.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RecetasFavoritas extends StatefulWidget {
  const RecetasFavoritas({Key? key}) : super(key: key);

  @override
  _RecetasFavoritasState createState() => _RecetasFavoritasState();
}

class _RecetasFavoritasState extends State<RecetasFavoritas> {
  Map<String, bool> _favorites = {};
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserIdAndFavorites();
  }

  Future<void> _loadUserIdAndFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (!mounted) return;
      setState(() => _userId = user.uid);
      await _loadUserFavorites(user.uid);
    } else {
      if (!mounted) return;
      setState(() => _userId = null);
    }
  }

  Future<void> _loadUserFavorites(String userId) async {
    try {
      final favoritesSnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .collection('favoritos')
          .get();
      final favorites = <String, bool>{};
      for (var doc in favoritesSnapshot.docs) {
        favorites[doc.id] = true;
      }
      if (mounted) setState(() => _favorites = favorites);
    } catch (e) {
      print("Error al cargar favoritos: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al cargar favoritos: $e")),
        );
      }
    }
  }

  Future<void> _toggleFavorite(String recetaId) async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debes iniciar sesión para guardar favoritos")),
      );
      return;
    }
    final currentUserId = _userId!;
    final bool isCurrentlyFavorite = _favorites[recetaId] ?? false;
    final bool newFavoriteState = !isCurrentlyFavorite;

    if (mounted) setState(() => _favorites[recetaId] = newFavoriteState);

    try {
      final favRef = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(currentUserId)
          .collection('favoritos')
          .doc(recetaId);
      if (newFavoriteState) {
        await favRef.set({'recetaId': recetaId, 'addedAt': Timestamp.now()});
      } else {
        await favRef.delete();
      }
    } catch (e) {
      print("Error al actualizar favorito en Firestore: $e");
      if (mounted) {
        setState(() => _favorites[recetaId] = isCurrentlyFavorite);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al guardar favorito: ${e.toString()}")),
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
        title: const Text("Favoritos"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: "Ajustes",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaginaAjustes())),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Text(
              "Tus Recetas Favoritas",
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
          ),
          Expanded(
            child: _userId == null
                ? Center( // Mensaje si no hay usuario
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.no_accounts_outlined, size: 60, color: colorScheme.outline),
                        const SizedBox(height: 16),
                        Text(
                          "Inicia sesión para ver tus favoritos",
                          style: textTheme.bodyLarge?.copyWith(color: colorScheme.outline),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ).animate().fadeIn(delay: 200.ms),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('recetas')
                        .where(FieldPath.documentId, whereIn: _favorites.keys.isNotEmpty ? _favorites.keys.toList() : ['_dummy_id_'])
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator(color: colorScheme.primary));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center( // Mensaje si no hay favoritos o error
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.favorite_border_outlined, size: 60, color: colorScheme.outline),
                              const SizedBox(height: 16),
                              Text(
                                _favorites.isEmpty ? "Aún no tienes recetas favoritas" : "No se encontraron recetas favoritas.",
                                style: textTheme.bodyLarge?.copyWith(color: colorScheme.outline),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ).animate().fadeIn(delay: 200.ms),
                        );
                      }

                      final recetasDocs = snapshot.data!.docs;
                      final List<Receta> favoritas = recetasDocs.map((doc) {
                        return Receta.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
                      }).toList();

                      // --- GROUP RECIPES BY CATEGORY ---
                      final Map<String, List<Receta>> recetasPorCategoria = {};
                      for (final receta in favoritas) {
                        final categoria = receta.categoria.isNotEmpty ? receta.categoria : 'Sin Categoría';
                        recetasPorCategoria.putIfAbsent(categoria, () => []).add(receta);
                      }
                      // --- END GROUPING ---

                      // Opcional: Ordenar categorías alfabéticamente
                      final categoriasOrdenadas = recetasPorCategoria.keys.toList()..sort();

                      // --- BUILD LIST VIEW BY CATEGORY ---
                      return ListView.builder(
                        padding: const EdgeInsets.all(16), // Padding around the list
                        itemCount: categoriasOrdenadas.length, // Number of categories
                        itemBuilder: (context, index) {
                          final categoria = categoriasOrdenadas[index];
                          final recetasEnCategoria = recetasPorCategoria[categoria]!;

                          // Card for each category group
                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            clipBehavior: Clip.antiAlias,
                            child: ExpansionTile(
                              shape: const Border(),
                              collapsedShape: const Border(),
                              backgroundColor: colorScheme.surfaceContainerLowest,
                              leading: CircleAvatar( // Icono para la categoría
                                backgroundColor: colorScheme.primaryContainer,
                                foregroundColor: colorScheme.onPrimaryContainer,
                                child: Icon(_getCategoryIcon(categoria), size: 20),
                              ),
                              title: Text(
                                categoria, // Category name as title
                                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              childrenPadding: const EdgeInsets.only(bottom: 8, left: 16, right: 16), // Padding for items inside
                              children: recetasEnCategoria.map((receta) { // Map recipes in this category
                                final recetaId = receta.id;
                                final bool isFavorite = _favorites[recetaId] ?? false; // Check favorite status

                                // Build ListTile for each recipe
                                return InkWell( // Make the whole row tappable
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => DetalleReceta(receta: receta)),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10.0), // Vertical padding for each item
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center, // Center items vertically
                                      children: [
                                        ClipRRect( // Recipe Image
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            receta.urlImagen,
                                            width: 65, // Slightly smaller image
                                            height: 65,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, progress) {
                                              if (progress == null) return child;
                                              return Container(width: 65, height: 65, color: colorScheme.surfaceVariant, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
                                            },
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(width: 65, height: 65, color: colorScheme.surfaceVariant, child: Icon(Icons.broken_image_outlined, color: colorScheme.outline));
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded( // Recipe Info
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                receta.nombre,
                                                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold), // Slightly smaller title
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "Tiempo: ${receta.tiempoMinutos} min",
                                                style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                                              ),
                                              const SizedBox(height: 4),
                                              Row( // Rating Stars
                                                children: List.generate(5, (i) => Icon(
                                                  i < receta.calificacion ? Icons.star_rounded : Icons.star_border_rounded,
                                                  color: colorScheme.primary,
                                                  size: 16, // Smaller stars
                                                )),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Favorite Button
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                          icon: Icon(
                                            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                            color: isFavorite ? colorScheme.primary : colorScheme.outline,
                                          ),
                                          tooltip: isFavorite ? "Quitar de favoritos" : "Añadir a favoritos",
                                          onPressed: () => _toggleFavorite(recetaId),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ).animate().fadeIn(delay: (index * 100).ms); // Animate card entrance
                        },
                      );
                      // --- END LIST VIEW ---
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Helper function for category icons (copied from HistorialRecetas)
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
