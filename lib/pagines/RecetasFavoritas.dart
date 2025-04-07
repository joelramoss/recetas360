import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recetas360/components/DetalleReceta.dart';
import 'package:recetas360/components/Receta.dart';
import 'package:recetas360/pagines/InterfazAjustes.dart';

class RecetasFavoritas extends StatefulWidget {
  const RecetasFavoritas({Key? key}) : super(key: key);

  @override
  _RecetasFavoritasState createState() => _RecetasFavoritasState();
}

class _RecetasFavoritasState extends State<RecetasFavoritas> {
  Map<String, bool> _favorites = {};
  late String _userId;

  @override
  void initState() {
    super.initState();
    _loadUserIdAndFavorites();
  }

  // Cargar el ID del usuario y sus favoritos
  _loadUserIdAndFavorites() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      setState(() {
        _userId = user.uid; // Obtener el userId del usuario autenticado
      });
      _loadUserFavorites(user.uid);
    } else {
      // Si no hay usuario autenticado, manejar este caso (por ejemplo, mostrar mensaje de error)
      setState(() {
        _userId = "";
      });
    }
  }

  // Cargar los favoritos del usuario
  _loadUserFavorites(String userId) async {
    try {
      final favoritesSnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .collection('favoritos')
          .get();

      final favorites = <String, bool>{};
      for (var doc in favoritesSnapshot.docs) {
        favorites[doc.id] = true; // Marcar como favorito
      }

      setState(() {
        _favorites = favorites;
      });
    } catch (e) {
      print("Error al cargar favoritos: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double imageSize = screenWidth * 0.20;
    final double starSize = screenWidth * 0.06;
    final double cardPadding = screenWidth * 0.04;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orangeAccent,
        actions: [
          IconButton(
            iconSize: 32.0,
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PaginaAjustes(),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.orangeAccent,
              Colors.pink.shade100,
            ],
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: Center(
                child: Text(
                  "Recetas Favoritas",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 4,
                        color: Colors.black45,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('recetas')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No se encontraron recetas."));
                  }
                  final recetasDocs = snapshot.data!.docs;
                  final List<Receta> recetas = recetasDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    data['id'] = doc.id;
                    return Receta.fromFirestore(data);
                  }).toList();

                  // Filtrar solo las recetas favoritas
                  final favoritas = recetas.where((receta) {
                    return _favorites[receta.id] ?? false; // Verifica si la receta está marcada como favorita
                  }).toList();

                  return ListView.builder(
                    padding: EdgeInsets.all(cardPadding),
                    itemCount: favoritas.length,
                    itemBuilder: (context, index) {
                      final receta = favoritas[index];
                      final recetaId = receta.id;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetalleReceta(receta: receta),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 4,
                          margin: EdgeInsets.only(bottom: cardPadding),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(cardPadding),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    receta.urlImagen,
                                    width: imageSize,
                                    height: imageSize,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: imageSize,
                                        height: imageSize,
                                        color: Colors.grey.shade300,
                                        child: const Icon(Icons.image_not_supported),
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(width: cardPadding),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        receta.nombre,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Tiempo: ${receta.tiempoMinutos} min",
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: List.generate(5, (i) {
                                          return Icon(
                                            i < receta.calificacion
                                                ? Icons.star
                                                : Icons.star_border,
                                            color: Colors.orangeAccent,
                                            size: starSize,
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        _favorites[recetaId] ?? false
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: _favorites[recetaId] ?? false
                                            ? Colors.red
                                            : Colors.grey,
                                      ),
                                      onPressed: () async {
                                        final newValue = !(_favorites[recetaId] ?? false);
                                        setState(() {
                                          _favorites[recetaId] = newValue;
                                        });

                                        try {
                                          if (newValue) {
                                            await FirebaseFirestore.instance
                                                .collection('usuarios')
                                                .doc(_userId)
                                                .collection('favoritos')
                                                .doc(recetaId)
                                                .set({'recetaId': recetaId});
                                          } else {
                                            await FirebaseFirestore.instance
                                                .collection('usuarios')
                                                .doc(_userId)
                                                .collection('favoritos')
                                                .doc(recetaId)
                                                .delete();
                                          }
                                        } catch (e) {
                                          setState(() {
                                            _favorites[recetaId] = !(newValue);
                                          });
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text("Error al actualizar favorito: $e")),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
