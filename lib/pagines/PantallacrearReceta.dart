import 'dart:io'; // Necesario para File
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:recetas360/components/agregarReceta.dart';
import 'package:recetas360/components/Receta.dart';
import 'package:recetas360/components/nutritionalifno.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:recetas360/FirebaseServices.dart';
import 'package:recetas360/serveis/ImagePickerService.dart';
import 'package:recetas360/serveis/kInputDecoration.dart';
import 'package:recetas360/services/gemini_service.dart'; 

// Clase para manejar la entrada de ingredientes (nombre y cantidad como un solo string)
class IngredientInput {
  final TextEditingController quantityController;
  final TextEditingController nameController;

  String get quantityText => quantityController.text.trim();
  String get nameText => nameController.text.trim();

  // Combina la cantidad y el nombre en un solo string para la IA
  String get combinedText {
    final qty = quantityText;
    final name = nameText;
    if (qty.isNotEmpty && name.isNotEmpty) {
      return "$qty $name";
    } else if (name.isNotEmpty) {
      return name; // Si solo hay nombre, devolver solo el nombre
    }
    return ""; // Si ambos están vacíos o solo hay cantidad (lo cual es menos útil)
  }

  IngredientInput({String initialQuantity = '', String initialName = ''})
      : quantityController = TextEditingController(text: initialQuantity),
        nameController = TextEditingController(text: initialName);

  void dispose() {
    quantityController.dispose();
    nameController.dispose();
  }
}

class CrearRecetaScreen extends StatefulWidget {
  final String? initialCategoria;
  final String? initialGastronomia;

  const CrearRecetaScreen({
    super.key,
    this.initialCategoria,
    this.initialGastronomia,
  });

  @override
  _CrearRecetaScreenState createState() => _CrearRecetaScreenState();
}

class _CrearRecetaScreenState extends State<CrearRecetaScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _tiempoController = TextEditingController();

  File? _selectedImageFile;
  final StorageService _storageService = StorageService();
  final ImagePickerService _imagePickerService = ImagePickerService();
  late final GeminiService _geminiService; // Instancia de GeminiService

  final List<IngredientInput> _ingredients = [];
  final List<TextEditingController> _stepControllers = [];
  int _calificacion = 3;
  NutritionalInfo _totalInfo = NutritionalInfo.zero(); 

  bool _isSaving = false;
  bool _isCalculatingMacros = false; 
  bool _macrosEstanActualizados = false; // Nueva bandera

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

  bool _isCategoriaLocked = false;
  bool _isGastronomiaLocked = false;

  @override
  void initState() {
    super.initState();
    _geminiService = GeminiService(); 

    if (widget.initialCategoria != null) {
      _selectedCategoria = widget.initialCategoria;
      _isCategoriaLocked = true;
      if (categoriasConGastronomias.containsKey(_selectedCategoria)) {
        _gastronomiasDisponibles = categoriasConGastronomias[_selectedCategoria!]!;
      } else {
        _gastronomiasDisponibles = [];
      }
    }

    if (widget.initialGastronomia != null) {
      if (_selectedCategoria != null && _gastronomiasDisponibles.contains(widget.initialGastronomia)) {
        _selectedGastronomia = widget.initialGastronomia;
        _isGastronomiaLocked = true;
      }
    }

    _addIngredient();
    _addStep();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _tiempoController.dispose();
    for (var ing in _ingredients) {
      ing.dispose();
    }
    for (var controller in _stepControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addIngredient() {
    setState(() {
      _ingredients.add(IngredientInput());
      _macrosEstanActualizados = false; // Macros ya no están actualizados
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients[index].dispose();
      _ingredients.removeAt(index);
      _macrosEstanActualizados = false; // Macros ya no están actualizados
      // Considerar si recalcular inmediatamente o esperar al botón
      // Por ahora, solo marcamos como no actualizados.
      // Si quieres recalcular aquí, llama a _recalcularMacros()
      // pero ten en cuenta que se llamará por cada ingrediente quitado.
      // Es mejor que el usuario lo haga explícitamente o al guardar.
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

  Future<void> _recalcularMacros() async {
    if (_isCalculatingMacros) return;

    final List<String> ingredientesParaGemini = _ingredients
        .map((ing) => ing.combinedText) 
        .where((text) => text.isNotEmpty)
        .toList();

    if (ingredientesParaGemini.isEmpty) {
      if (mounted) {
        setState(() {
          _totalInfo = NutritionalInfo.zero();
          _macrosEstanActualizados = true; // Consideramos actualizados si no hay ingredientes
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isCalculatingMacros = true;
      });
    }

    try {
      final NutritionalInfo? infoEstimada =
          await _geminiService.estimarMacrosDeReceta(ingredientesParaGemini);
      if (mounted) {
        setState(() {
          _totalInfo = infoEstimada ?? NutritionalInfo.zero();
          _macrosEstanActualizados = true; // Macros actualizados tras el cálculo
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al estimar macros: $e")),
        );
        setState(() {
          _totalInfo = NutritionalInfo.zero();
          _macrosEstanActualizados = false; // Falló el cálculo, no están actualizados
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCalculatingMacros = false;
        });
      }
    }
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

    final List<String> ingredientesFinal = _ingredients
        .map((ing) => ing.combinedText) 
        .where((text) => text.isNotEmpty)
        .toList();

    if (ingredientesFinal.isEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text("Añade al menos un ingrediente.",
                 style: TextStyle(color: Theme.of(context).colorScheme.onError)),
             backgroundColor: Theme.of(context).colorScheme.error,
           ),
         );
         return;
    }
    for (var i = 0; i < _ingredients.length; i++) {
      final ing = _ingredients[i];
      if (ing.nameText.isEmpty) { 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "El nombre del ingrediente ${i + 1} está vacío. Por favor, complétalo.",
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
    
    // Solo recalcular si los macros no están actualizados o si no hay ingredientes (para asegurar que _totalInfo es zero)
    if (!_macrosEstanActualizados || ingredientesFinal.isEmpty) {
      await _recalcularMacros();
      // Pequeña pausa para asegurar que el estado se actualice si _recalcularMacros fue muy rápido
      // y para que el usuario vea el cambio si hubo un cálculo.
      await Future.delayed(const Duration(milliseconds: 100)); 
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
        creadorId: FirebaseAuth.instance.currentUser?.uid, // Ejemplo
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

  Widget _buildIngredientRow(int index) {
    final ing = _ingredients[index];
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          SizedBox(
            width: 100, 
            child: TextFormField(
              controller: ing.quantityController,
              decoration: kInputDecoration(
                  context: context,
                  labelText: "Cant.", 
                  hintText: "Ej: 100g",
                  isDense: true, 
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12), 
                ),
              onChanged: (value) { // Marcar que los macros ya no están actualizados
                setState(() {
                  _macrosEstanActualizados = false;
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: ing.nameController,
              decoration: kInputDecoration(
                  context: context,
                  labelText: "Alimento ${index + 1}",
                  hintText: "Ej: Pechuga de pollo",
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Nombre vacío";
                }
                return null;
              },
              onChanged: (value) { // Marcar que los macros ya no están actualizados
                setState(() {
                  _macrosEstanActualizados = false;
                });
              },
            ),
          ),
          if (_ingredients.length > 1)
            IconButton(
              icon: Icon(Icons.remove_circle_outline, color: colorScheme.error),
              tooltip: "Quitar ingrediente",
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero, 
              constraints: const BoxConstraints(), 
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
              decoration: kInputDecoration(context: context, labelText: "Paso ${index + 1}"),
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    const defaultFillColor = Colors.white;
    final lockedFillColor = Colors.grey.shade200;
    final consistentInputBorder = OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outline,
          width: 1.0,
        ),
      );
    final focusedConsistentInputBorder = consistentInputBorder.copyWith(
        borderSide: BorderSide(
          color: colorScheme.primary,
          width: 2.0,
        ),
      );
    final errorConsistentInputBorder = consistentInputBorder.copyWith(
        borderSide: BorderSide(
          color: colorScheme.error,
          width: 1.5,
        ),
      );
    final focusedErrorConsistentInputBorder = consistentInputBorder.copyWith(
        borderSide: BorderSide(
          color: colorScheme.error,
          width: 2.0,
        ),
      );

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
                      Text("Imagen de la Receta", style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      Center(
                        child: GestureDetector(
                          onTap: _isSaving ? null : () => _imagePickerService.showImageSourceActionSheet(
                              context: context,
                              onImageSelected: (file) {
                                if (file != null) {
                                  setState(() {
                                    _selectedImageFile = file;
                                  });
                                }
                              },
                            ),
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
                                  width: 1),
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
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nombreController,
                        decoration: kInputDecoration(
                          context: context,
                          labelText: "Nombre de la receta",
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa un nombre para la receta';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descripcionController,
                        decoration: kInputDecoration(
                          context: context,
                          labelText: "Descripción",
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa una descripción';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _tiempoController,
                        decoration: kInputDecoration(context: context, labelText: "Tiempo de Preparación (min)"),
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
                              decoration: InputDecoration(
                                labelText: "Categoría",
                                filled: true,
                                fillColor: _isCategoriaLocked ? lockedFillColor : defaultFillColor,
                                border: consistentInputBorder,
                                enabledBorder: consistentInputBorder,
                                focusedBorder: focusedConsistentInputBorder,
                                errorBorder: errorConsistentInputBorder,
                                focusedErrorBorder: focusedErrorConsistentInputBorder,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
                              ),
                              hint: const Text('Selecciona'),
                              items: categoriasConGastronomias.keys
                                  .map((String categoria) {
                                return DropdownMenuItem<String>(
                                  value: categoria,
                                  child: Text(categoria),
                                );
                              }).toList(),
                              onChanged: _isCategoriaLocked
                                  ? null
                                  : (String? newValue) {
                                      setState(() {
                                        _selectedCategoria = newValue;
                                        _selectedGastronomia = null;
                                        _isGastronomiaLocked = false;
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
                              decoration: InputDecoration(
                                labelText: "Gastronomía",
                                filled: true,
                                fillColor: _isGastronomiaLocked ? lockedFillColor : defaultFillColor,
                                border: consistentInputBorder,
                                enabledBorder: consistentInputBorder,
                                focusedBorder: focusedConsistentInputBorder,
                                errorBorder: errorConsistentInputBorder,
                                focusedErrorBorder: focusedErrorConsistentInputBorder,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
                              ),
                              hint: _selectedCategoria == null ? const Text('Elige categoría') : const Text('Selecciona'),
                              items: _gastronomiasDisponibles
                                  .map((String gastronomia) {
                                return DropdownMenuItem<String>(
                                  value: gastronomia,
                                  child: Text(gastronomia),
                                );
                              }).toList(),
                              onChanged: _isGastronomiaLocked || _selectedCategoria == null
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
                      const SizedBox(height: 10),
                      Center(
                        child: ElevatedButton.icon(
                          icon: _isCalculatingMacros
                              ? Container(
                                  width: 18, height: 18,
                                  margin: const EdgeInsets.only(right: 8),
                                  child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary),
                                )
                              : Icon(Icons.calculate_outlined, size: 20),
                          label: Text(_isCalculatingMacros ? "Calculando..." : "Calcular Macros"),
                          onPressed: _isCalculatingMacros || _ingredients.every((ing) => ing.combinedText.isEmpty)
                              ? null
                              : _recalcularMacros,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.secondary,
                            foregroundColor: colorScheme.onSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              // ... (Sección de Pasos sin cambios)
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
              // ... (Sección de Información Adicional y Macros)
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
                      Text("Macros Totales:",
                          style: textTheme.titleMedium),
                      const SizedBox(height: 4),
                      if (_isCalculatingMacros)
                        const Center(child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                              SizedBox(width: 8),
                              Text("Estimando macros..."),
                            ],
                          ),
                        ))
                      else
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
                  onPressed: _isSaving || _isCalculatingMacros ? null : _saveRecipe,
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
