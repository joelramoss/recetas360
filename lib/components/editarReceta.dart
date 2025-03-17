import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recetas360/components/Receta.dart';
import 'package:recetas360/components/producto.dart';
import 'package:recetas360/components/selecciondeproducto.dart';
import 'package:recetas360/components/nutritionalifno.dart'; // Si quieres recalcular macros
import 'package:recetas360/components/apiservice.dart'; // Si necesitas la lógica de productos, etc.

// Clase auxiliar (misma que en CrearRecetaScreen) para ingredientes
class IngredientSelection {
  String name;
  Producto? selected;

  IngredientSelection({required this.name, this.selected});
}

class EditarReceta extends StatefulWidget {
  final Receta receta;
  const EditarReceta({Key? key, required this.receta}) : super(key: key);

  @override
  _EditarRecetaState createState() => _EditarRecetaState();
}

class _EditarRecetaState extends State<EditarReceta> {
  // Controladores para campos principales
  late TextEditingController _nombreController;
  late TextEditingController _urlImagenController;
  late TextEditingController _descripcionController;
  late TextEditingController _tiempoController;
  late TextEditingController _categoriaController;
  late TextEditingController _gastronomiaController;

  // Dinámica de ingredientes
  List<IngredientSelection> _ingredients = [];

  // Dinámica de pasos
  List<TextEditingController> _stepControllers = [];

  int _calificacion = 3;

  // Info nutricional acumulada (opcional, si usas macros)
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
    _nombreController = TextEditingController(text: widget.receta.nombre);
    _urlImagenController = TextEditingController(text: widget.receta.urlImagen);
    _descripcionController = TextEditingController(text: widget.receta.descripcion);
    _tiempoController =
        TextEditingController(text: widget.receta.tiempoMinutos.toString());
    _categoriaController = TextEditingController(text: widget.receta.categoria);
    _gastronomiaController = TextEditingController(text: widget.receta.gastronomia);
    _calificacion = widget.receta.calificacion;

    // Convertir ingredientes a la lista dynamic
    // Aquí no tenemos info de producto real, a menos que la hayas guardado antes.
    // Suponiendo que solo guardabas el "nombre" en la DB, los convertimos a IngredientSelection con selected = null.
    for (var ingName in widget.receta.ingredientes) {
      _ingredients.add(IngredientSelection(name: ingName, selected: null));
    }
    // Si no hay ingredientes, forzamos al menos uno vacío
    if (_ingredients.isEmpty) {
      _ingredients.add(IngredientSelection(name: ''));
    }

    // Convertir pasos a controladores
    if (widget.receta.pasos.isNotEmpty) {
      for (var p in widget.receta.pasos) {
        _stepControllers.add(TextEditingController(text: p));
      }
    } else {
      _stepControllers.add(TextEditingController());
    }

    // Si usas macros, inicializa _totalInfo (si lo guardaste) o recalcúlalo
    if (widget.receta.nutritionalInfo != null) {
      _totalInfo = NutritionalInfo.fromMap(widget.receta.nutritionalInfo!);
    }
    // O bien, si deseas recalcular con la API de productos, hazlo:
    _recalcularMacros();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _urlImagenController.dispose();
    _descripcionController.dispose();
    _tiempoController.dispose();
    _categoriaController.dispose();
    _gastronomiaController.dispose();
    for (var c in _stepControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _recalcularMacros() {
    // Si no necesitas macros, puedes omitir esta parte.
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

  // Construir fila de ingrediente (igual que en CrearRecetaScreen)
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
          ),
        ),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () async {
            if (ing.name.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Ingresa el nombre del ingrediente"),
                ),
              );
              return;
            }
            // Selección de producto
            Producto? producto = await showProductoSelection(context, ing.name);
            if (producto != null) {
              setState(() {
                ing.selected = producto;
              });
              _recalcularMacros();
            }
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

  // Construir fila de paso
  Widget _buildStepRow(int index) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _stepControllers[index],
            decoration: InputDecoration(labelText: "Paso ${index + 1}"),
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

  Future<void> _updateReceta() async {
    // Convertir ingredientes a lista de nombres
    List<String> ingredientesFinal =
        _ingredients.map((i) => i.selected?.nombre ?? i.name).toList();

    // Convertir pasos
    List<String> pasos = _stepControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    // Info nutricional
    Map<String, dynamic> nutritionalMap = _totalInfo.toMap();

    final docRef =
        FirebaseFirestore.instance.collection('recetas').doc(widget.receta.id);

    await docRef.update({
      'nombre': _nombreController.text,
      'urlImagen': _urlImagenController.text,
      'descripcion': _descripcionController.text,
      'tiempoMinutos': int.tryParse(_tiempoController.text) ??
          widget.receta.tiempoMinutos,
      'categoria': _categoriaController.text,
      'gastronomia': _gastronomiaController.text,
      'calificacion': _calificacion,
      'ingredientes': ingredientesFinal,
      'pasos': pasos,
      'nutritionalInfo': nutritionalMap,
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar con fondo naranja
      appBar: AppBar(
        backgroundColor: Colors.orangeAccent,
        actions: [
          IconButton(
            iconSize: 32.0,
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              // Ajustes
            },
          ),
        ],
      ),
      body: Container(
        // Mismo estilo de fondo degradado
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
            // Cabecera de 50 px
            Container(
              width: double.infinity,
              height: 50,
              child: const Center(
                child: Text(
                  "Editar Receta",
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _nombreController,
                          decoration:
                              const InputDecoration(labelText: "Nombre"),
                        ),
                        TextField(
                          controller: _urlImagenController,
                          decoration:
                              const InputDecoration(labelText: "URL de la imagen"),
                        ),
                        TextField(
                          controller: _descripcionController,
                          decoration:
                              const InputDecoration(labelText: "Descripción"),
                          maxLines: 3,
                        ),
                        TextField(
                          controller: _tiempoController,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: "Tiempo (min)"),
                        ),
                        TextField(
                          controller: _categoriaController,
                          decoration:
                              const InputDecoration(labelText: "Categoría"),
                        ),
                        TextField(
                          controller: _gastronomiaController,
                          decoration:
                              const InputDecoration(labelText: "Gastronomía"),
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
                          onChanged: (val) {
                            setState(() {
                              _calificacion = val.toInt();
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orangeAccent,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: _updateReceta,
                            child: const Text(
                              "Guardar Cambios",
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
          ],
        ),
      ),
    );
  }
}