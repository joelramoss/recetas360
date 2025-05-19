import 'dart:io'; // Necesario para File
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Para seleccionar imágenes
import 'package:recetas360/components/agregarReceta.dart';
import 'package:recetas360/components/Receta.dart';
import 'package:recetas360/components/nutritionalifno.dart';
import 'package:recetas360/components/selecciondeproducto.dart';
import 'package:recetas360/components/producto.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:recetas360/FirebaseServices.dart'; // Para StorageService

class IngredientSelection {
  String name;
  Producto? selected;
  final TextEditingController controller;

  IngredientSelection({required this.name, this.selected})
      : controller = TextEditingController(text: name);
}

class CrearRecetaScreen extends StatefulWidget {
  const CrearRecetaScreen({super.key});

  @override
  _CrearRecetaScreenState createState() => _CrearRecetaScreenState();
}

class _CrearRecetaScreenState extends State<CrearRecetaScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _tiempoController = TextEditingController();

  File? _selectedImageFile; // Para almacenar la imagen seleccionada
  final ImagePicker _picker = ImagePicker(); // Instancia de ImagePicker
  final StorageService _storageService = StorageService(); // Instancia de StorageService

  final List<IngredientSelection> _ingredients = [];
  final List<TextEditingController> _stepControllers = [];
  int _calificacion = 3;
  NutritionalInfo _totalInfo = NutritionalInfo(
      energy: 0.0,
      proteins: 0.0,
      carbs: 0.0,
      fats: 0.0,
      saturatedFats: 0.0);

  bool _isSaving = false;

  final Map<String, List<String>> categoriasConGastronomias = {
    "Carne": ["Asiatica", "Mediterranea", "Americana", "Africana", "Oceanica"],
    "Pescado": ["Asiatica", "Mediterranea", "Oceanica"],
    "Verduras": ["Asiatica", "Mediterranea", "Africana", "Americana"],
    "Lácteos": ["Mediterranea", "Americana"],
    "Cereales": ["Asiatica", "Mediterranea", "Americana"],
  };

  String? _selectedCategoria;
  String? _selectedGastronomia;
  List<String> _gastronomiasDisponibles = [];

  @override
  void initState() {
    super.initState();
    _addIngredient();
    _addStep();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _tiempoController.dispose();
    for (var ing in _ingredients) {
      ing.controller.dispose();
    }
    for (var controller in _stepControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addIngredient() {
    setState(() {
      _ingredients.add(IngredientSelection(name: ''));
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients[index].controller.dispose();
      _ingredients.removeAt(index);
      _recalcularMacros();
    });
  }

  void _addStep() {
    setState(() {
      _stepControllers.add(TextEditingController());
    });
  }

  void _removeStep(int index) {
    setState(() {
      _stepControllers[index].dispose();
      _stepControllers.removeAt(index);
    });
  }

  void _recalcularMacros() {
    NutritionalInfo total = NutritionalInfo(
        energy: 0.0,
        proteins: 0.0,
        carbs: 0.0,
        fats: 0.0,
        saturatedFats: 0.0);
    for (var ing in _ingredients) {
      if (ing.selected != null) {
        final producto = ing.selected!;
        final infoFromProducto = NutritionalInfo(
          energy: producto.valorEnergetico ?? 0.0,
          proteins: producto.proteinas ?? 0.0,
          carbs: producto.carbohidratos ?? 0.0,
          fats: producto.grasas ?? 0.0,
          saturatedFats: producto.grasasSaturadas ?? 0.0,
        );
        total = total + infoFromProducto;
      }
    }
    if (mounted) {
      setState(() {
        _totalInfo = total;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70, // Comprime la imagen para reducir tamaño
        maxWidth: 1024, // Redimensiona si es muy grande
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      print("Error al seleccionar imagen: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Error al seleccionar imagen: ${e.toString()}",
                  style: TextStyle(color: Theme.of(context).colorScheme.onError)),
              backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    }
  }

  Widget _buildIngredientRow(int index) {
    final ing = _ingredients[index];
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextFormField(
              controller: ing.controller,
              decoration: InputDecoration(
                labelText: "Ingrediente ${index + 1}",
                isDense: true,
              ),
              onChanged: (value) {
                ing.name = value;
              },
              validator: (value) =>
                  value == null || value.isEmpty ? "Ingrediente vacío" : null,
            ),
          ),
          IconButton(
            icon: Icon(Icons.search_outlined, color: colorScheme.primary),
            tooltip: "Buscar producto",
            visualDensity: VisualDensity.compact,
            onPressed: () {
              final currentName = ing.controller.text.trim();
              if (currentName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        "Ingresa el nombre del ingrediente para buscar",
                        style: TextStyle(color: colorScheme.onError)),
                    backgroundColor: colorScheme.error,
                  ),
                );
                return;
              }
              showProductoSelection(context, currentName).then((producto) {
                if (producto != null && mounted) {
                  setState(() {
                    ing.selected = producto;
                  });
                  _recalcularMacros();
                }
              });
            },
          ),
          if (ing.selected != null)
            Padding(
              padding: const EdgeInsets.only(left: 4.0, right: 4.0),
              child: Icon(Icons.check_circle_outline_rounded,
                  color: Colors.green.shade600, size: 20),
            ),
          if (_ingredients.length > 1)
            IconButton(
              icon: Icon(Icons.remove_circle_outline, color: colorScheme.error),
              tooltip: "Quitar ingrediente",
              visualDensity: VisualDensity.compact,
              onPressed: () => _removeIngredient(index),
            ),
        ],
      ),
    );
  }

  Widget _buildStepRow(int index) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _stepControllers[index],
              decoration: InputDecoration(
                labelText: "Paso ${index + 1}",
                isDense: true,
              ),
              maxLines: null,
              keyboardType: TextInputType.multiline,
              validator: (value) =>
                  value == null || value.isEmpty ? "Paso vacío" : null,
            ),
          ),
          if (_stepControllers.length > 1)
            IconButton(
              icon: Icon(Icons.remove_circle_outline, color: colorScheme.error),
              tooltip: "Quitar paso",
              visualDensity: VisualDensity.compact,
              onPressed: () => _removeStep(index),
            ),
        ],
      ),
    );
  }

  Future<void> _saveRecipe() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) return;

    if (_selectedImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Por favor, selecciona una imagen para la receta",
              style: TextStyle(color: Theme.of(context).colorScheme.onError)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    for (var i = 0; i < _ingredients.length; i++) {
      if (_ingredients[i].selected == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Busca y selecciona un producto para '${_ingredients[i].controller.text}' (Ingrediente ${i + 1})",
                style: TextStyle(color: Theme.of(context).colorScheme.onError)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }
    }

    if (_stepControllers.any((c) => c.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Asegúrate de que todos los pasos tengan descripción",
              style: TextStyle(color: Theme.of(context).colorScheme.onError)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    String? imageUrl;

    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString() + "_" + _selectedImageFile!.path.split('/').last;
      final destination = 'recetas_imagenes/$fileName';
      imageUrl = await _storageService.subirArchivo(_selectedImageFile!, destination);

      if (imageUrl == null) {
        throw Exception("Error al subir la imagen.");
      }

      List<String> ingredientesFinal = _ingredients.map((i) => i.selected!.nombre).toList();
      List<String> pasos = _stepControllers.map((c) => c.text.trim()).toList();
      int tiempoMinutos = int.tryParse(_tiempoController.text) ?? 0;
      Map<String, dynamic> nutritionalMap = _totalInfo.toMap();

      Receta nuevaReceta = Receta(
        id: '',
        nombre: _nombreController.text.trim(),
        urlImagen: imageUrl,
        ingredientes: ingredientesFinal,
        descripcion: _descripcionController.text.trim(),
        tiempoMinutos: tiempoMinutos,
        calificacion: _calificacion,
        nutritionalInfo: nutritionalMap,
        categoria: _selectedCategoria!,
        gastronomia: _selectedGastronomia!,
        pasos: pasos,
      );

      await agregarReceta(nuevaReceta);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Receta creada exitosamente")),
      );
      Navigator.pop(context);
    } catch (e) {
      print("Error saving recipe: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al guardar la receta: ${e.toString()}",
              style: TextStyle(color: Theme.of(context).colorScheme.onError)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Crear Nueva Receta"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Información General",
                          style: textTheme.titleLarge
                              ?.copyWith(color: colorScheme.primary)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nombreController,
                        decoration: const InputDecoration(
                            labelText: "Nombre de la Receta"),
                        validator: (value) => value == null || value.isEmpty
                            ? "Ingresa el nombre"
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text("Imagen de la Receta", style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                                context: context,
                                builder: (BuildContext bc) {
                                  return SafeArea(
                                    child: Wrap(
                                      children: <Widget>[
                                        ListTile(
                                            leading: const Icon(Icons.photo_library),
                                            title: const Text('Galería'),
                                            onTap: () {
                                              _pickImage(ImageSource.gallery);
                                              Navigator.of(context).pop();
                                            }),
                                        ListTile(
                                          leading: const Icon(Icons.photo_camera),
                                          title: const Text('Cámara'),
                                          onTap: () {
                                            _pickImage(ImageSource.camera);
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                });
                          },
                          child: Container(
                            height: 180,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: _selectedImageFile == null
                                      ? colorScheme.outlineVariant
                                      : Colors.transparent,
                                  width: _selectedImageFile == null ? 1 : 0),
                            ),
                            child: _selectedImageFile != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(11),
                                    child: Image.file(
                                      _selectedImageFile!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo_outlined,
                                          size: 48,
                                          color: colorScheme.primary),
                                      const SizedBox(height: 8),
                                      Text("Toca para seleccionar imagen",
                                          style: textTheme.bodyMedium?.copyWith(
                                              color: colorScheme.onSurfaceVariant)),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descripcionController,
                        decoration:
                            const InputDecoration(labelText: "Descripción"),
                        maxLines: 3,
                        keyboardType: TextInputType.multiline,
                        validator: (value) => value == null || value.isEmpty
                            ? "Ingresa la descripción"
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _tiempoController,
                        decoration: const InputDecoration(
                            labelText: "Tiempo de Preparación (min)"),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Ingresa el tiempo";
                          }
                          if (int.tryParse(value) == null ||
                              int.parse(value) <= 0) {
                            return "Tiempo inválido (número > 0)";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedCategoria,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: "Categoría",
                              ),
                              hint: const Text('Selecciona'),
                              items: categoriasConGastronomias.keys
                                  .map((String categoria) {
                                return DropdownMenuItem<String>(
                                  value: categoria,
                                  child: Text(categoria),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedCategoria = newValue;
                                  _selectedGastronomia = null;
                                  _gastronomiasDisponibles =
                                      categoriasConGastronomias[newValue] ?? [];
                                });
                              },
                              validator: (value) => value == null
                                  ? 'Selecciona categoría'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedGastronomia,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: "Gastronomía",
                              ),
                              hint: const Text('Selecciona'),
                              disabledHint: const Text('Elige categoría primero'),
                              items: _gastronomiasDisponibles
                                  .map((String gastronomia) {
                                return DropdownMenuItem<String>(
                                  value: gastronomia,
                                  child: Text(gastronomia),
                                );
                              }).toList(),
                              onChanged: _selectedCategoria == null
                                  ? null
                                  : (String? newValue) {
                                      setState(() {
                                        _selectedGastronomia = newValue;
                                      });
                                    },
                              validator: (value) => value == null
                                  ? 'Selecciona gastronomía'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ]
                        .animate(interval: 100.ms)
                        .fadeIn(duration: 300.ms)
                        .slideX(begin: -0.1),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text("Ingredientes",
                                style: textTheme.titleLarge
                                    ?.copyWith(color: colorScheme.primary)),
                          ),
                          TextButton.icon(
                            icon:
                                const Icon(Icons.add_circle_outline, size: 20),
                            label: const Text(""),
                            onPressed: _addIngredient,
                            style: TextButton.styleFrom(
                                foregroundColor: colorScheme.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(),
                        itemCount: _ingredients.length,
                        itemBuilder: (context, index) {
                          return _buildIngredientRow(index)
                              .animate()
                              .fadeIn(delay: (100 * index).ms);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Pasos de Preparación",
                              style: textTheme.titleLarge
                                  ?.copyWith(color: colorScheme.primary)),
                          TextButton.icon(
                            icon:
                                const Icon(Icons.add_circle_outline, size: 20),
                            label: const Text(""),
                            onPressed: _addStep,
                            style: TextButton.styleFrom(
                                foregroundColor: colorScheme.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _stepControllers.length,
                        itemBuilder: (context, index) {
                          return _buildStepRow(index)
                              .animate()
                              .fadeIn(delay: (100 * index).ms);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Información Adicional",
                          style: textTheme.titleLarge
                              ?.copyWith(color: colorScheme.primary)),
                      const SizedBox(height: 16),
                      Text("Macros Totales (estimados):",
                          style: textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 16,
                        runSpacing: 4,
                        children: [
                          Text(
                              "Energía: ${_totalInfo.energy.toStringAsFixed(0)} kcal",
                              style: textTheme.bodyMedium),
                          Text(
                              "Proteínas: ${_totalInfo.proteins.toStringAsFixed(1)} g",
                              style: textTheme.bodyMedium),
                          Text(
                              "Carbs: ${_totalInfo.carbs.toStringAsFixed(1)} g",
                              style: textTheme.bodyMedium),
                          Text(
                              "Grasas: ${_totalInfo.fats.toStringAsFixed(1)} g",
                              style: textTheme.bodyMedium),
                          Text(
                              "Saturadas: ${_totalInfo.saturatedFats.toStringAsFixed(1)} g",
                              style: textTheme.bodyMedium),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text("Calificación:", style: textTheme.titleMedium),
                      Slider(
                        value: _calificacion.toDouble(),
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: _calificacion.toString(),
                        activeColor: colorScheme.primary,
                        inactiveColor: colorScheme.primary.withOpacity(0.3),
                        onChanged: (value) {
                          setState(() {
                            _calificacion = value.toInt();
                          });
                        },
                      ),
                    ]
                        .animate(interval: 100.ms)
                        .fadeIn(duration: 300.ms)
                        .slideX(begin: 0.1),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    textStyle: textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  onPressed: _isSaving ? null : _saveRecipe,
                  icon: _isSaving
                      ? Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.only(right: 8),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: colorScheme.onPrimary),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_isSaving ? "Guardando..." : "Guardar Receta"),
                )
                    .animate()
                    .fadeIn(delay: 500.ms)
                    .shake(delay: 500.ms),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
