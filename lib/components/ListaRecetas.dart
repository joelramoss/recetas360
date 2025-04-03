import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recetas360/components/DetalleReceta.dart';
import 'package:recetas360/components/Receta.dart';
import 'package:recetas360/components/editarReceta.dart';
import 'package:recetas360/pagines/InterfazAjustes.dart';
import 'package:recetas360/pagines/PantallacrearReceta.dart';
import 'package:recetas360/pagines/HistorialRecetas.dart';

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
  // Mapa local para almacenar el estado favorito de cada receta, basado en el doc.id.
  final Map<String, bool> _favorites = {};

  @override
  Widget build(BuildContext context) {
    // Dimensiones de la pantalla para un layout responsivo.
    final double screenWidth = MediaQuery.of(context).size.width;
    final double imageSize = screenWidth * 0.20;    // La imagen ocupará ~20% del ancho.
    final double starSize = screenWidth * 0.06;     // Tamaño relativo para las estrellas.
    final double cardPadding = screenWidth * 0.04;  // Padding y márgenes relativos.

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orangeAccent,
        actions: [
          // Agregar botón de historial
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            iconSize: 32,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HistorialRecetas(),
                ),
              );
            },
          ),
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
        // Fondo degradado
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
            // Encabezado
            SizedBox(
              width: double.infinity,
              height: 50,
              child: Center(
                child: Text(
                  "Recetas: ${widget.mainCategory} - ${widget.subCategory}",
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
            // Lista de recetas con StreamBuilder
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('recetas')
                    .where('categoria', isEqualTo: widget.mainCategory)
                    .where('gastronomia', isEqualTo: widget.subCategory)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No se encontraron recetas."));
                  }
                  final recetasDocs = snapshot.data!.docs;
                  // Convertir los documentos en objetos Receta, incluyendo el ID.
                  final List<Receta> recetas = recetasDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    data['id'] = doc.id;
                    // Si el campo 'isFavorite' no existe, se asume false.
                    _favorites[doc.id] = data['isFavorite'] ?? false;
                    return Receta.fromFirestore(data);
                  }).toList();

                  return ListView.builder(
                    padding: EdgeInsets.all(cardPadding),
                    itemCount: recetas.length + 1,
                    itemBuilder: (context, index) {
                      // Al llegar al final, mostramos el botón para crear receta
                      if (index == recetas.length) {
                        return Padding(
                          padding: EdgeInsets.only(
                            top: cardPadding,
                            bottom: cardPadding * 2,
                          ),
                          child: Center(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orangeAccent,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: cardPadding * 2,
                                  vertical: cardPadding,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const CrearRecetaScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: const Text(
                                "Crear Receta",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        );
                      }

                      final receta = recetas[index];
                      final isFavorite = _favorites[receta.id] ?? false;

                      // Construimos la tarjeta de cada receta con un layout personalizado
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
                          color: isFavorite ? Colors.pink.shade100 : Colors.white,
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
                                // Imagen
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
                                // Texto (nombre, tiempo, estrellas) en una columna expandida
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
                                // Íconos de acciones (favorito, editar, eliminar) en una columna
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        isFavorite ? Icons.favorite : Icons.favorite_border,
                                        color: isFavorite ? Colors.red : Colors.grey,
                                      ),
                                      onPressed: () async {
                                        final newValue = !isFavorite;
                                        setState(() {
                                          _favorites[receta.id] = newValue;
                                        });
                                        try {
                                          await FirebaseFirestore.instance
                                              .collection('recetas')
                                              .doc(receta.id)
                                              .update({'isFavorite': newValue});
                                        } catch (e) {
                                          // Si falla, revertir el cambio
                                          setState(() {
                                            _favorites[receta.id] = isFavorite;
                                          });
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text("Error al actualizar favorito: $e")),
                                          );
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => EditarReceta(receta: receta),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text("Eliminar receta"),
                                            content: const Text("¿Estás seguro que deseas eliminar esta receta?"),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, false),
                                                child: const Text("Cancelar"),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, true),
                                                child: const Text("Eliminar"),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          await FirebaseFirestore.instance
                                              .collection('recetas')
                                              .doc(receta.id)
                                              .delete();
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