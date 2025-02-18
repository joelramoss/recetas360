import 'package:flutter/material.dart';

class ListaRecetas extends StatelessWidget {
  final String mainCategory;
  final String subCategory;

  const ListaRecetas({Key? key, required this.mainCategory, required this.subCategory}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Recetas: $mainCategory - $subCategory"),
        backgroundColor: Colors.orangeAccent,
      ),
      body: Center(
        child: Text(
          "Aquí se mostrarán las recetas para:\n$mainCategory - $subCategory",
          style: TextStyle(fontSize: 18, color: Colors.grey.shade800),
          textAlign: TextAlign.center,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orangeAccent,
        foregroundColor: Colors.white,
        onPressed: () {
          // Aquí se abre el formulario para crear receta.
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Nueva Receta"),
              content: const Text("Formulario para crear receta..."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cerrar"),
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
