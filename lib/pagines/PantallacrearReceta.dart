import 'package:flutter/material.dart';
import 'package:recetas360/components/agregarReceta.dart';
import 'package:recetas360/components/Receta.dart';
import 'package:recetas360/components/nutritionalifno.dart'; // NutritionalInfo, getRecipeNutritionalInfo
import 'package:recetas360/components/apiservice.dart';
import 'package:recetas360/components/selecciondeproducto.dart';
import 'package:recetas360/components/producto.dart';

// Clase auxiliar para el manejo de ingredientes seleccionados
class IngredientSelection {
  String name;
  Producto? selected;

  IngredientSelection({required this.name, this.selected});
}

class CrearRecetaScreen extends StatefulWidget {
  const CrearRecetaScreen({Key? key}) : super(key: key);

  @override
  _CrearRecetaScreenState createState() => _CrearRecetaScreenState();
}

class _CrearRecetaScreenState extends State<CrearRecetaScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _urlImagenController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _tiempoController = TextEditingController();
  final TextEditingController _categoriaController = TextEditingController();
  final TextEditingController _gastronomiaController = TextEditingController();

  // Lista dinámica para los ingredientes
  List<IngredientSelection> _ingredients = [];

  // Lista dinámica para los pasos
  List<TextEditingController> _stepControllers = [];

  int _calificacion = 3;

  // Acumulador de información nutricional
  NutritionalInfo _totalInfo = NutritionalInfo(
    energy: 0,
    proteins: 0,
    carbs: 0,
    fats: 0,
    saturatedFats: 0,
  );

  @override
  void initState() {
    super.initState();
    // Comenzamos con un ingrediente vacío y un paso vacío
    _ingredients.add(IngredientSelection(name: ''));
    _stepControllers.add(TextEditingController());
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _urlImagenController.dispose();
    _descripcionController.dispose();
    _tiempoController.dispose();
    _categoriaController.dispose();
    _gastronomiaController.dispose();
    for (var controller in _stepControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Función para recalcular macros si usas selección de productos
  void _recalcularMacros() {
    NutritionalInfo total = NutritionalInfo(
      energy: 0,
      proteins: 0,
      carbs: 0,
      fats: 0,
      saturatedFats: 0,
    );
    for (var ing in _ingredients) {
      if (ing.selected != null) {
        total = total +
            NutritionalInfo(
              energy: ing.selected!.valorEnergetico,
              proteins: ing.selected!.proteinas,
              carbs: ing.selected!.carbohidratos,
              fats: ing.selected!.grasas,
              saturatedFats: ing.selected!.grasasSaturadas,
            );
      }
    }
    setState(() {
      _totalInfo = total;
    });
  }

  Widget _buildIngredientRow(int index) {
    final ing = _ingredients[index];
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            initialValue: ing.name,
            decoration: const InputDecoration(labelText: "Ingrediente"),
            onChanged: (value) {
              ing.name = value;
            },
            validator: (value) =>
                value == null || value.isEmpty ? "Ingresa un ingrediente" : null,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            if (ing.name.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Ingresa el nombre del ingrediente"),
                ),
              );
              return;
            }
            
            // Usar un contexto capturado en el momento del clic
            showProductoSelection(context, ing.name).then((producto) {
              if (producto != null && mounted) {
                setState(() {
                  ing.selected = producto;
                });
                _recalcularMacros();
              }
            });
          },
        ),
        if (ing.selected != null) const Icon(Icons.check, color: Colors.green),
        if (_ingredients.length > 1)
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
            onPressed: () {
              setState(() {
                _ingredients.removeAt(index);
                _recalcularMacros();
              });
            },
          ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
          onPressed: () {
            setState(() {
              _ingredients.add(IngredientSelection(name: ''));
            });
          },
        ),
      ],
    );
  }

  Widget _buildStepRow(int index) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _stepControllers[index],
            decoration: InputDecoration(labelText: "Paso ${index + 1}"),
            validator: (value) =>
                value == null || value.isEmpty ? "Ingresa un paso" : null,
          ),
        ),
        if (_stepControllers.length > 1)
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
            onPressed: () {
              setState(() {
                _stepControllers.removeAt(index);
              });
            },
          ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
          onPressed: () {
            setState(() {
              _stepControllers.add(TextEditingController());
            });
          },
        ),
      ],
    );
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) return;
    for (var ing in _ingredients) {
      if (ing.selected == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Selecciona un producto para '${ing.name}'")),
        );
        return;
      }
    }

    // Convertir ingredientes a lista de nombres de productos
    List<String> ingredientesFinal =
        _ingredients.map((i) => i.selected!.nombre).toList();
    // Convertir pasos
    List<String> pasos = _stepControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    int tiempoMinutos = int.tryParse(_tiempoController.text) ?? 0;
    Map<String, dynamic> nutritionalMap = _totalInfo.toMap();

    Receta nuevaReceta = Receta(
      nombre: _nombreController.text,
      urlImagen: _urlImagenController.text,
      ingredientes: ingredientesFinal,
      descripcion: _descripcionController.text,
      tiempoMinutos: tiempoMinutos,
      calificacion: _calificacion,
      nutritionalInfo: nutritionalMap,
      categoria: _categoriaController.text,
      gastronomia: _gastronomiaController.text,
      pasos: pasos,
    );

    await agregarReceta(nuevaReceta);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Receta creada exitosamente")),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Mantén el AppBar o ajusta según desees
      appBar: AppBar(
        title: const Text("Crear Receta"),
        backgroundColor: Colors.orangeAccent,
      ),
      body: Container(
        // Mismo estilo de fondo que en EditarReceta
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
            // Cabecera de 50 px con texto (opcional, si quieres igual que EditarReceta)
            Container(
              width: double.infinity,
              height: 50,
              child: const Center(
                child: Text(
                  "Crear Receta",
                  style: TextStyle(
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
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _nombreController,
                            decoration:
                                const InputDecoration(labelText: "Nombre de la Receta"),
                            validator: (value) => value == null || value.isEmpty
                                ? "Ingresa el nombre"
                                : null,
                          ),
                          TextFormField(
                            controller: _urlImagenController,
                            decoration:
                                const InputDecoration(labelText: "URL de la imagen"),
                            validator: (value) => value == null || value.isEmpty
                                ? "Ingresa la URL"
                                : null,
                          ),
                          TextFormField(
                            controller: _descripcionController,
                            decoration:
                                const InputDecoration(labelText: "Descripción"),
                            maxLines: 2,
                            validator: (value) => value == null || value.isEmpty
                                ? "Ingresa la descripción"
                                : null,
                          ),
                          TextFormField(
                            controller: _tiempoController,
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(labelText: "Tiempo (min)"),
                            validator: (value) => value == null || value.isEmpty
                                ? "Ingresa el tiempo"
                                : null,
                          ),
                          TextFormField(
                            controller: _categoriaController,
                            decoration: const InputDecoration(
                                labelText: "Categoría (ej. Carne)"),
                            validator: (value) => value == null || value.isEmpty
                                ? "Ingresa la categoría"
                                : null,
                          ),
                          TextFormField(
                            controller: _gastronomiaController,
                            decoration: const InputDecoration(
                                labelText: "Gastronomía (ej. Asiatica)"),
                            validator: (value) => value == null || value.isEmpty
                                ? "Ingresa la gastronomía"
                                : null,
                          ),
                          const SizedBox(height: 16),
                          const Text("Pasos:",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Column(
                            children: List.generate(_stepControllers.length, (index) {
                              return _buildStepRow(index);
                            }),
                          ),
                          const SizedBox(height: 16),
                          const Text("Ingredientes:",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Column(
                            children: List.generate(_ingredients.length, (index) {
                              return _buildIngredientRow(index);
                            }),
                          ),
                          const SizedBox(height: 16),
                          const Text("Macros Totales (estimados):"),
                          Text("Energía: ${_totalInfo.energy} kcal"),
                          Text("Proteínas: ${_totalInfo.proteins} g"),
                          Text("Carbohidratos: ${_totalInfo.carbs} g"),
                          Text("Grasas: ${_totalInfo.fats} g"),
                          Text("Grasas Saturadas: ${_totalInfo.saturatedFats} g"),
                          const SizedBox(height: 16),
                          const Text("Calificación:",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Slider(
                            value: _calificacion.toDouble(),
                            min: 1,
                            max: 5,
                            divisions: 4,
                            label: _calificacion.toString(),
                            onChanged: (value) {
                              setState(() {
                                _calificacion = value.toInt();
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orangeAccent,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: _saveRecipe,
                              icon: const Icon(Icons.save),
                              label: const Text(
                                "Guardar Receta",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
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
