import 'package:flutter/material.dart';

class ListaRecetas extends StatelessWidget {
  const ListaRecetas({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ejemplo de pantalla donde se muestran las recetas
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Recetas"),
        backgroundColor: Colors.orangeAccent,
      ),
      body: Center(
        child: Text(
          "Aquí se mostrarán todas las recetas",
          style: TextStyle(fontSize: 18, color: Colors.grey.shade800),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orangeAccent,
        foregroundColor: Colors.white,
        onPressed: () {
          // Aquí se podría abrir el formulario de creación de receta.
          // Por ejemplo, mostrando un diálogo o navegando a otra pantalla.
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
