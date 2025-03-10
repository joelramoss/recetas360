import 'package:flutter/material.dart';
import 'package:recetas360/components/apiservice.dart'; // Para buscar productos en la API
import 'producto.dart';          // Modelo de Producto
import 'Receta.dart';            // Modelo de Receta
import 'nutritionalifno.dart';   // Contiene la clase NutritionalInfo

// Función para mostrar el diálogo de selección de producto para un ingrediente
Future<Producto?> showProductoSelection(BuildContext context, String ingrediente) async {
  ApiService apiService = ApiService();
  // Busca productos para el ingrediente
  List<Producto> productos = await apiService.buscarProductos(ingrediente);

  return showDialog<Producto>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Selecciona el producto para "$ingrediente"'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: productos.length,
            itemBuilder: (context, index) {
              final producto = productos[index];
              return ListTile(
                title: Text(producto.nombre),
                subtitle: Text('Valor Energético: ${producto.valorEnergetico} kcal'),
                onTap: () {
                  Navigator.of(context).pop(producto);
                },
              );
            },
          ),
        ),
      );
    },
  );
}

class DetalleReceta extends StatefulWidget {
  final Receta receta;

  const DetalleReceta({Key? key, required this.receta}) : super(key: key);

  @override
  _DetalleRecetaState createState() => _DetalleRecetaState();
}

class _DetalleRecetaState extends State<DetalleReceta> {
  // Guarda las selecciones hechas por el usuario para cada ingrediente
  Map<String, Producto> productosSeleccionados = {};
  // Variable que almacena el futuro de la información nutricional
  Future<NutritionalInfo>? nutritionalInfoFuture;

  @override
  void initState() {
    super.initState();
    // Inicialmente, se calcula la información nutricional usando el primer resultado de cada búsqueda
    nutritionalInfoFuture = _getNutritionalInfo();
  }

  // Función que muestra el diálogo y guarda la selección del producto para un ingrediente
  Future<void> _seleccionarProducto(String ingrediente) async {
    Producto? seleccionado = await showProductoSelection(context, ingrediente);
    if (seleccionado != null) {
      setState(() {
        productosSeleccionados[ingrediente] = seleccionado;
        // Se actualiza el futuro para recalcular la tabla nutricional
        nutritionalInfoFuture = _getNutritionalInfo();
      });
    }
  }

  // Función para calcular la información nutricional de la receta usando los productos seleccionados.
  // Si no se ha seleccionado ninguno para un ingrediente, se usa el primer producto encontrado.
  Future<NutritionalInfo> _getNutritionalInfo() async {
    NutritionalInfo total = NutritionalInfo(
      energy: 0,
      proteins: 0,
      carbs: 0,
      fats: 0,
      saturatedFats: 0,
    );
    ApiService apiService = ApiService();

    for (String ing in widget.receta.ingredientes) {
      Producto? producto;
      if (productosSeleccionados.containsKey(ing)) {
        producto = productosSeleccionados[ing];
      } else {
        List<Producto> productos = await apiService.buscarProductos(ing);
        if (productos.isNotEmpty) {
          producto = productos.first;
        }
      }
      if (producto != null) {
        total = total +
            NutritionalInfo(
              energy: producto.valorEnergetico,
              proteins: producto.proteinas,
              carbs: producto.carbohidratos,
              fats: producto.grasas,
              saturatedFats: producto.grasasSaturadas,
            );
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receta.nombre),
        backgroundColor: Colors.orangeAccent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade50, Colors.orange.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagen de la receta
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      widget.receta.urlImagen,
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
                    widget.receta.nombre,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  // Tiempo de preparación
                  Row(
                    children: [
                      const Icon(Icons.timer, color: Colors.orangeAccent),
                      const SizedBox(width: 8),
                      Text("${widget.receta.tiempoMinutos} min", style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  const Divider(height: 32, thickness: 1),
                  // Lista de ingredientes con botón para seleccionar el producto adecuado
                  const Text(
                    "Ingredientes:",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...widget.receta.ingredientes.map((ing) {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        border: Border.all(color: Colors.orangeAccent, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(ing, style: const TextStyle(fontSize: 16)),
                          ElevatedButton.icon(
                            onPressed: () => _seleccionarProducto(ing),
                            icon: const Icon(Icons.search, size: 24),
                            label: const Text("Seleccionar"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orangeAccent,
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const Divider(height: 32, thickness: 1),
                  // Descripción de la receta
                  const Text(
                    "Descripción:",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.receta.descripcion,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.justify,
                  ),
                  const Divider(height: 32, thickness: 1),
                  // Sección de la tabla nutricional actualizada
                  const Text(
                    "Tabla Nutricional (aproximada) 100g / 100ml:",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  FutureBuilder<NutritionalInfo>(
                    future: nutritionalInfoFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      } else if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text("Error al cargar datos nutricionales: ${snapshot.error}"),
                        );
                      } else if (!snapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text("No se pudieron obtener datos nutricionales."),
                        );
                      } else {
                        final info = snapshot.data!;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Valor Energético: ${info.energy.toStringAsFixed(2)} kcal"),
                              Text("Proteínas: ${info.proteins.toStringAsFixed(2)} g"),
                              Text("Carbohidratos: ${info.carbs.toStringAsFixed(2)} g"),
                              Text("Grasas: ${info.fats.toStringAsFixed(2)} g"),
                              Text("Grasas Saturadas: ${info.saturatedFats.toStringAsFixed(2)} g"),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      // Botón inferior "Iniciar"
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  // Acción para el botón "Iniciar"
                },
                child: const Text(
                  "Iniciar",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}
