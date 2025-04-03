import 'package:flutter/material.dart';
import 'Receta.dart';
import 'nutritionalifno.dart';
import 'package:recetas360/components/PasosRecetaScreen.dart';

class DetalleReceta extends StatelessWidget {
  final Receta receta;

  const DetalleReceta({Key? key, required this.receta}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final NutritionalInfo info = receta.nutritionalInfo != null
        ? NutritionalInfo.fromMap(receta.nutritionalInfo!)
        : NutritionalInfo(
            energy: 0,
            proteins: 0,
            carbs: 0,
            fats: 0,
            saturatedFats: 0,
          );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orangeAccent,
        actions: [
          IconButton(
            iconSize: 32.0,
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              // Acción para abrir ajustes
              // Navigator.push(...);
            },
          ),
        ],
      ),
      body: Container(
        // Mismo fondo degradado que en ListaRecetas
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
            // Encabezado con 50 px de alto, igual que en ListaRecetas
            Container(
              width: double.infinity,
              height: 50,
              child: Center(
                child: Text(
                  "Detalle de la Receta",
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
            // El resto del contenido en un Expanded con SingleChildScrollView
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Imagen de la receta
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            receta.urlImagen,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                color: Colors.grey.shade300,
                                child: const Center(
                                  child: Icon(Icons.image_not_supported, size: 50),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Título de la receta
                        Text(
                          receta.nombre,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        // Tiempo de preparación
                        Row(
                          children: [
                            const Icon(Icons.timer, color: Colors.orangeAccent),
                            const SizedBox(width: 8),
                            Text("${receta.tiempoMinutos} min",
                                style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                        const Divider(height: 32, thickness: 1),
                        // Lista de ingredientes
                        const Text(
                          "Ingredientes:",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...receta.ingredientes.map((ing) {
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              border: Border.all(color: Colors.orangeAccent, width: 1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(ing, style: const TextStyle(fontSize: 16)),
                          );
                        }).toList(),
                        const Divider(height: 32, thickness: 1),
                        // Descripción
                        const Text(
                          "Descripción:",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          receta.descripcion,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.justify,
                        ),
                        const Divider(height: 32, thickness: 1),
                        // Tabla nutricional
                        const Text(
                          "Tabla Nutricional (aproximada) 100g / 100ml:",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Text("Valor Energético: ${info.energy.toStringAsFixed(2)} kcal"),
                        Text("Proteínas: ${info.proteins.toStringAsFixed(2)} g"),
                        Text("Carbohidratos: ${info.carbs.toStringAsFixed(2)} g"),
                        Text("Grasas: ${info.fats.toStringAsFixed(2)} g"),
                        Text("Grasas Saturadas: ${info.saturatedFats.toStringAsFixed(2)} g"),
                        const Divider(height: 32, thickness: 1),
                        // Categoría y gastronomía
                        Text(
                          "Categoría: ${receta.categoria}",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Gastronomía: ${receta.gastronomia}",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 32),
                        // Botón "Iniciar"
                        Center(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orangeAccent,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: () {
                              // Mantener solo la navegación a la pantalla de pasos
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PasosRecetaScreen(receta: receta),
                                ),
                              );
                            },
                            child: const Text(
                              "Iniciar",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
