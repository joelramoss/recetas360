import 'dart:io'; // Necesario para File
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recetas360/FirebaseServices.dart';
import 'package:recetas360/serveis/kInputDecoration.dart'; // Asegúrate que esta importación esté
import 'package:recetas360/serveis/ImagePickerService.dart'; // Importar
import 'package:recetas360/components/Receta.dart';
import 'package:recetas360/components/producto.dart';
import 'package:recetas360/components/selecciondeproducto.dart';
import 'package:recetas360/components/nutritionalifno.dart';
import 'package:flutter_animate/flutter_animate.dart';

// --- Ingredient Selection Helper Class ---
class IngredientSelection {
  String name;
  Producto? selected;
  TextEditingController controller;

  IngredientSelection({required this.name, this.selected})
      : controller = TextEditingController(text: name);

  void dispose() {
    controller.dispose();
  }
}

// --- Edit Recipe Screen ---
class EditarReceta extends StatefulWidget {
  final Receta receta;
  const EditarReceta({super.key, required this.receta});

  @override
  _EditarRecetaState createState() => _EditarRecetaState();
}

class _EditarRecetaState extends State<EditarReceta> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _tiempoController;
  late TextEditingController _categoriaController;
  late TextEditingController _gastronomiaController;

  List<IngredientSelection> _ingredients = [];
  List<TextEditingController> _stepControllers = [];
  double _calificacion = 3.0;

  // --- Nuevas variables de estado para añadir pasos ---
  final TextEditingController _newStepController = TextEditingController();
  bool _isAddingNewStep = false;
  final FocusNode _newStepFocusNode = FocusNode();
  // --- Fin nuevas variables ---

  File? _selectedImageFile;
  String? _currentImageUrl;
  final StorageService _storageService = StorageService();
  final ImagePickerService _imagePickerService = ImagePickerService();

  bool _isSaving = false;
  NutritionalInfo _totalInfo = NutritionalInfo(energy: 0.0, proteins: 0.0, carbs: 0.0, fats: 0.0, saturatedFats: 0.0);

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.receta.nombre);
    _currentImageUrl = widget.receta.urlImagen;
    _descripcionController = TextEditingController(text: widget.receta.descripcion);
    _tiempoController = TextEditingController(text: widget.receta.tiempoMinutos.toString());
    _categoriaController = TextEditingController(text: widget.receta.categoria);
    _gastronomiaController = TextEditingController(text: widget.receta.gastronomia);
    _calificacion = widget.receta.calificacion.toDouble();

    _ingredients = widget.receta.ingredientes
        .map((name) => IngredientSelection(name: name, selected: null))
        .toList();
    if (_ingredients.isEmpty) _ingredients.add(IngredientSelection(name: ''));

    _stepControllers = widget.receta.pasos
        .map((step) => TextEditingController(text: step))
        .toList();
    if (_stepControllers.isEmpty) _stepControllers.add(TextEditingController());

    if (widget.receta.nutritionalInfo != null) {
      try {
        _totalInfo = NutritionalInfo.fromMap(widget.receta.nutritionalInfo!);
      } catch (e) {
        print("Error parsing saved nutritional info: $e");
        _totalInfo = NutritionalInfo(energy: 0.0, proteins: 0.0, carbs: 0.0, fats: 0.0, saturatedFats: 0.0);
      }
    } else {
       _totalInfo = NutritionalInfo(energy: 0.0, proteins: 0.0, carbs: 0.0, fats: 0.0, saturatedFats: 0.0);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _tiempoController.dispose();
    _categoriaController.dispose();
    _gastronomiaController.dispose();
    for (var ing in _ingredients) {
      ing.dispose();
    }
    for (var c in _stepControllers) {
      c.dispose();
    }
    _newStepController.dispose(); // Dispose nuevo controlador
    _newStepFocusNode.dispose(); // Dispose nuevo focus node
    super.dispose();
  }

  void _recalcularMacros() {
    NutritionalInfo total = NutritionalInfo(energy: 0.0, proteins: 0.0, carbs: 0.0, fats: 0.0, saturatedFats: 0.0);
    for (var ing in _ingredients) {
      if (ing.selected != null) {
        total += NutritionalInfo(
          energy: ing.selected!.valorEnergetico,
          proteins: ing.selected!.proteinas,
          carbs: ing.selected!.carbohidratos,
          fats: ing.selected!.grasas,
          saturatedFats: ing.selected!.grasasSaturadas,
        );
      }
    }
    setState(() => _totalInfo = total);
  }

  Widget _buildIngredientRow(int index, ColorScheme colorScheme) {
    final ing = _ingredients[index];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextFormField(
              controller: ing.controller,
              decoration: kInputDecoration(context: context, labelText: "Ingrediente ${index + 1}", isDense: true),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Vacío' : null,
              onChanged: (value) => ing.name = value.trim(),
              enabled: !_isSaving,
            ),
          ),
          IconButton(
            icon: Icon(Icons.search_rounded, color: colorScheme.secondary),
            tooltip: "Buscar producto",
            onPressed: _isSaving ? null : () async {
              final currentName = ing.controller.text.trim();
              if (currentName.isEmpty) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ingresa un nombre para buscar")));
                 return;
              }
              FocusScope.of(context).unfocus();
              Producto? producto = await showProductoSelection(context, currentName);
              if (producto != null) {
                 setState(() => ing.selected = producto);
                 _recalcularMacros();
              }
            },
             visualDensity: VisualDensity.compact,
          ),
          if (ing.selected != null) Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 20),
          if (_ingredients.length > 1)
            IconButton(
              icon: Icon(Icons.remove_circle_outline_rounded, color: colorScheme.error),
              tooltip: "Quitar ingrediente",
              onPressed: _isSaving ? null : () {
                 setState(() {
                    _ingredients.removeAt(index).dispose();
                    _recalcularMacros();
                 });
              },
               visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Widget _buildStepRow(int index, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextFormField(
              controller: _stepControllers[index],
              decoration: kInputDecoration(context: context, labelText: "Paso ${index + 1}", isDense: true),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Vacío' : null,
              maxLines: null,
              keyboardType: TextInputType.multiline,
               enabled: !_isSaving,
            ),
          ),
          IconButton(
            icon: Icon(Icons.remove_circle_outline_rounded, color: colorScheme.error),
            tooltip: "Quitar paso",
            onPressed: _isSaving || _stepControllers.length <= 1 ? null : () {
               setState(() => _stepControllers.removeAt(index).dispose());
            },
             visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  void _addIngredient() => setState(() => _ingredients.add(IngredientSelection(name: '')));
  
  void _addStep() {
    setState(() {
      _isAddingNewStep = true;
    });
    // Solicitar foco después de que el widget se construya
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) { // Asegurarse que el widget sigue montado
        FocusScope.of(context).requestFocus(_newStepFocusNode);
      }
    });
  }

  void _confirmAndAddStep() {
    final newStepText = _newStepController.text.trim();
    if (newStepText.isNotEmpty) {
      setState(() {
        _stepControllers.add(TextEditingController(text: newStepText));
        _newStepController.clear();
        _isAddingNewStep = false;
      });
    } else {
      // Si está vacío, simplemente ocultamos la UI de añadir y limpiamos
      setState(() {
        _newStepController.clear();
        _isAddingNewStep = false;
      });
    }
  }

  void _cancelAddNewStep() {
    setState(() {
      _newStepController.clear();
      _isAddingNewStep = false;
    });
  }

   Widget _buildSectionHeader(BuildContext context, String title) {
     return Padding(
       padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
       child: Text(
         title,
         style: Theme.of(context).textTheme.titleMedium?.copyWith(
               color: Theme.of(context).colorScheme.primary,
               fontWeight: FontWeight.w600,
             ),
       ),
     );
   }

  Future<void> _updateReceta() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa los campos requeridos.')),
      );
      return;
    }

    if (_isSaving) return;
    setState(() => _isSaving = true);
    final colorScheme = Theme.of(context).colorScheme;

    String finalImageUrl = _currentImageUrl ?? '';

    try {
      if (_selectedImageFile != null) {
        print("Procesando nueva imagen seleccionada...");

        if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
          print("Intentando eliminar imagen antigua: $_currentImageUrl");
          await _storageService.eliminarArchivoPorUrl(_currentImageUrl!);
        }

        final uniqueFileName = DateTime.now().millisecondsSinceEpoch.toString() + "_" + _selectedImageFile!.path.split('/').last;
        final destinationPath = 'recetas_imagenes/$uniqueFileName';

        print("Subiendo nueva imagen a: $destinationPath");
        String? uploadedFileUrl = await _storageService.subirArchivo(_selectedImageFile!, destinationPath);

        if (uploadedFileUrl != null && uploadedFileUrl.isNotEmpty) {
          finalImageUrl = uploadedFileUrl;
          print("Nueva imagen subida exitosamente: $finalImageUrl");
        } else {
          throw Exception("Error al subir la nueva imagen. El servicio de subida no devolvió una URL válida.");
        }
      }

      if (finalImageUrl.isEmpty) {
        throw Exception("La receta debe tener una imagen.");
      }

      List<String> ingredientesFinal = _ingredients.map((ing) => ing.controller.text.trim()).where((name) => name.isNotEmpty).toList();
      List<String> pasosFinal = _stepControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
      Map<String, dynamic> nutritionalMap = _totalInfo.toMap();

      final docRef = FirebaseFirestore.instance.collection('recetas').doc(widget.receta.id);

      print("Actualizando documento de receta en Firestore con URL de imagen: $finalImageUrl");
      await docRef.update({
        'nombre': _nombreController.text.trim(),
        'urlImagen': finalImageUrl,
        'descripcion': _descripcionController.text.trim(),
        'tiempoMinutos': int.tryParse(_tiempoController.text.trim()) ?? widget.receta.tiempoMinutos,
        'categoria': _categoriaController.text.trim(),
        'gastronomia': _gastronomiaController.text.trim(),
        'calificacion': _calificacion.round(),
        'ingredientes': ingredientesFinal,
        'pasos': pasosFinal,
        'nutritionalInfo': nutritionalMap,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Receta actualizada con éxito!')),
      );
      Navigator.pop(context);

    } catch (e) {
      print("Error detallado al actualizar receta: $e");
      if (e is FirebaseException) {
        print("Detalles de FirebaseException: Código: ${e.code}, Mensaje: ${e.message}");
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar la receta: ${e.toString()}', style: TextStyle(color: colorScheme.onError)),
          backgroundColor: colorScheme.error,
          duration: const Duration(seconds: 5),
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
    // final bool isDark = Theme.of(context).brightness == Brightness.dark; // No es necesario para lockedFillColor si es un gris fijo
    
    // Color para campos bloqueados (Categoría y Gastronomía en modo edición)
    final lockedFillColor = Colors.grey.shade200; // Un gris claro para contraste con el blanco

    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Receta"),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSectionHeader(context, "Información Básica"),
            TextFormField(
              controller: _nombreController,
              decoration: kInputDecoration(context: context, labelText: "Nombre de la Receta", icon: Icons.restaurant_menu_rounded),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
               enabled: !_isSaving, textCapitalization: TextCapitalization.sentences,
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 12),

            Text("Imagen de la Receta", style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Center(
              child: GestureDetector(
                onTap: _isSaving ? null : () => _imagePickerService.showImageSourceActionSheet(
                    context: context,
                    onImageSelected: (file) {
                      setState(() {
                        _selectedImageFile = file;
                      });
                    },
                  ),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: (_selectedImageFile == null && (_currentImageUrl == null || _currentImageUrl!.isEmpty))
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
                      : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Image.network(
                                _currentImageUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (context, error, stackTrace) =>
                                  const Center(child: Icon(Icons.broken_image_outlined, size: 48)),
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(child: CircularProgressIndicator());
                                },
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
            ).animate().fadeIn(delay: 150.ms),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descripcionController,
              decoration: kInputDecoration(context: context, labelText: "Descripción", icon: Icons.description_outlined),
              maxLines: 3, enabled: !_isSaving, textCapitalization: TextCapitalization.sentences,
            ).animate().fadeIn(delay: 200.ms),
             const SizedBox(height: 12),
             Row(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                  Expanded(
                     child: TextFormField(
                        controller: _tiempoController,
                        decoration: kInputDecoration(context: context, labelText: "Tiempo (min)", icon: Icons.timer_outlined),
                        keyboardType: const TextInputType.numberWithOptions(decimal: false),
                         enabled: !_isSaving,
                        validator: (v) {
                           if (v == null || v.trim().isEmpty) return 'Requerido';
                           if (int.tryParse(v.trim()) == null) return 'Número inválido';
                           return null;
                        },
                     ).animate().fadeIn(delay: 250.ms),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text("Calificación", style: textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                         Slider(
                           value: _calificacion,
                           min: 0, max: 5, divisions: 5,
                           label: _calificacion.round().toString(),
                           onChanged: _isSaving ? null : (value) => setState(() => _calificacion = value),
                         ).animate().fadeIn(delay: 300.ms),
                       ],
                     ),
                  ),
               ],
             ),
            const SizedBox(height: 12),
            Row(
              children: [
                 Expanded(
                    child: TextFormField(
                       controller: _categoriaController,
                       decoration: kInputDecoration(
                         context: context,
                         labelText: "Categoría",
                         icon: Icons.category_outlined
                       ).copyWith(fillColor: lockedFillColor), // Fondo gris para campo bloqueado
                       readOnly: true,
                       textCapitalization: TextCapitalization.words,
                         validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ).animate().fadeIn(delay: 350.ms),
                 ),
                 const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                       controller: _gastronomiaController,
                       decoration: kInputDecoration(
                         context: context,
                         labelText: "Gastronomía",
                         icon: Icons.public_rounded
                       ).copyWith(fillColor: lockedFillColor), // Fondo gris para campo bloqueado
                       readOnly: true, 
                       textCapitalization: TextCapitalization.words,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ).animate().fadeIn(delay: 400.ms),
                 ),
              ],
            ),

            _buildSectionHeader(context, "Ingredientes"),
            ...List.generate(_ingredients.length, (index) => _buildIngredientRow(index, colorScheme))
                .animate(interval: 50.ms).fadeIn().slideX(begin: -0.1),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text("Añadir Ingrediente"),
                onPressed: _isSaving ? null : _addIngredient,
              ),
            ),

            _buildSectionHeader(context, "Pasos"),
             ...List.generate(_stepControllers.length, (index) => _buildStepRow(index, colorScheme))
                 .animate(interval: 50.ms).fadeIn().slideX(begin: -0.1),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text("Añadir Paso"),
                onPressed: _isSaving || _isAddingNewStep ? null : _addStep,
              ),
            ),

            // --- UI para añadir nuevo paso (condicional) ---
            if (_isAddingNewStep)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _newStepController,
                      focusNode: _newStepFocusNode,
                      decoration: kInputDecoration(
                        context: context,
                        labelText: "Nuevo paso",
                        hintText: "Describe el nuevo paso...",
                        isDense: true,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: null, 
                      keyboardType: TextInputType.multiline,
                      validator: (value) {
                        // Opcional: puedes añadir una validación aquí si es necesario
                        // antes de permitir que se guarde, aunque _confirmAndAddStep ya verifica si está vacío.
                        // if (value == null || value.trim().isEmpty) {
                        //   return 'El paso no puede estar vacío';
                        // }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _cancelAddNewStep,
                          child: const Text("Cancelar"),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _confirmAndAddStep,
                          child: const Text("Aceptar"),
                        ),
                      ],
                    ),
                  ],
                ).animate().fadeIn().slideY(begin: 0.2),
              ),
            // --- Fin UI para añadir nuevo paso ---

             _buildSectionHeader(context, "Información Nutricional (Estimada)"),
             Card(
                elevation: 0,
                color: colorScheme.secondaryContainer.withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                 child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      _totalInfo.toString(),
                      style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSecondaryContainer),
                    ),
                 ),
             ).animate().fadeIn(delay: 500.ms),
             const SizedBox(height: 32),

            ElevatedButton.icon(
              icon: _isSaving ? Container(width: 20, height: 20, margin: const EdgeInsets.only(right: 8), child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary)) : const Icon(Icons.save_rounded),
              label: Text(_isSaving ? 'Guardando...' : 'Guardar Cambios'),
              style: ElevatedButton.styleFrom(
                 minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: _isSaving ? null : _updateReceta,
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.5),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}