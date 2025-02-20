import 'package:flutter/material.dart';
import 'package:recetas360/components/DetalleReceta.dart';
import 'receta.dart';

class ListaRecetas extends StatelessWidget {
  final String mainCategory;
  final String subCategory;

  const ListaRecetas({
    Key? key,
    required this.mainCategory,
    required this.subCategory,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Lista de recetas de ejemplo
    final List<Receta> recetas = [
      Receta(
        nombre: 'Ensalada Mediterránea',
        urlImagen: 'https://via.placeholder.com/150',
        ingredientes: ['Lechuga', 'Tomate', 'Queso feta', 'Aceitunas'],
        descripcion:
            'Ensalada fresca con ingredientes típicos del Mediterráneo.',
        tiempoMinutos: 15,
      ),
      Receta(
        nombre: 'Pizza Casera',
        urlImagen: 'https://via.placeholder.com/150',
        ingredientes: ['Harina', 'Tomate', 'Mozzarella', 'Aceite de oliva'],
        descripcion: 'Pizza con masa hecha a mano y salsa casera.',
        tiempoMinutos: 40,
      ),
      Receta(
        nombre: 'Sopa Asiática',
        urlImagen: 'https://via.placeholder.com/150',
        ingredientes: ['Fideos', 'Caldo', 'Verduras', 'Tofu'],
        descripcion: 'Sopa reconfortante con un toque exótico.',
        tiempoMinutos: 30,
      ),
      Receta(
        nombre: 'Sopa Asiática',
        urlImagen: 'https://via.placeholder.com/150',
        ingredientes: ['Fideos', 'Caldo', 'Verduras', 'Tofu'],
        descripcion: 'Sopa reconfortante con un toque exótico.',
        tiempoMinutos: 30,
      ),
    ];

    // Usamos itemCount = recetas.length + 1 para incluir el botón de +
    return Scaffold(
      appBar: AppBar(
        title: Text("Recetas: $mainCategory - $subCategory"),
        backgroundColor: Colors.orangeAccent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade100, Colors.pink.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: recetas.length + 1,
          itemBuilder: (context, index) {
            if (index < recetas.length) {
              final receta = recetas[index];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      receta.urlImagen,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image_not_supported),
                        );
                      },
                    ),
                  ),
                  title: Text(
                    receta.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Tiempo: ${receta.tiempoMinutos} min"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetalleReceta(receta: receta),
                      ),
                    );
                  },
                ),
              );
            } else {
              // Último elemento: el botón de +
              return Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 32),
                child: Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {
                      // Por ahora no hace nada; aquí se implementaría la acción para crear una receta
                    },
                    icon: const Icon(Icons.add),
                    label: const Text(
                      "Crear Receta",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
