import 'dart:io'; // Necesario para File
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; // Para seleccionar imágenes
import 'package:firebase_storage/firebase_storage.dart'; // Para Firebase Storage
import 'package:recetas360/components/Receta.dart';
import 'package:recetas360/components/producto.dart';
import 'package:recetas360/components/selecciondeproducto.dart';
import 'package:recetas360/components/nutritionalifno.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:recetas360/FirebaseServices.dart'; // Asumo que tienes tu StorageService aquí

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

  File? _selectedImageFile; // Para la nueva imagen seleccionada
  String? _currentImageUrl; // Para la URL de la imagen existente
  final ImagePicker _picker = ImagePicker();
  final StorageService _storageService = StorageService(); // Tu servicio de Storage

  bool _isSaving = false;
  NutritionalInfo _totalInfo = NutritionalInfo(energy: 0.0, proteins: 0.0, carbs: 0.0, fats: 0.0, saturatedFats: 0.0);

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.receta.nombre);
    _currentImageUrl = widget.receta.urlImagen; // Guardar la URL actual
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
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1024,
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

  InputDecoration _inputDecoration({
    required BuildContext context,
    required String label,
    IconData? icon,
    bool dense = false,
    String? hintText,
  }) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: icon != null ? Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 20) : null,
      isDense: dense,
      contentPadding: dense ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10) : null,
    );
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
              decoration: _inputDecoration(context: context, label: "Ingrediente ${index + 1}", dense: true),
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
              decoration: _inputDecoration(context: context, label: "Paso ${index + 1}", dense: true),
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
  void _addStep() => setState(() => _stepControllers.add(TextEditingController()));

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

    // Inicia con la URL actual o una cadena vacía si no hay imagen actual.
    String finalImageUrl = _currentImageUrl ?? '';

    try {
      // Si el usuario seleccionó un nuevo archivo de imagen
      if (_selectedImageFile != null) {
        print("Procesando nueva imagen seleccionada...");

        // Paso 1: Intentar eliminar la imagen antigua si existía.
        if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
          print("Intentando eliminar imagen antigua: $_currentImageUrl");
          await _storageService.eliminarArchivoPorUrl(_currentImageUrl!);
        }

        // Paso 2: Subir la nueva imagen.
        final uniqueFileName = DateTime.now().millisecondsSinceEpoch.toString() + "_" + _selectedImageFile!.path.split('/').last;
        final destinationPath = 'recetas_imagenes/$uniqueFileName'; // Asegúrate que esta ruta coincide con tus reglas de Storage

        print("Subiendo nueva imagen a: $destinationPath");
        String? uploadedFileUrl = await _storageService.subirArchivo(_selectedImageFile!, destinationPath);

        if (uploadedFileUrl != null && uploadedFileUrl.isNotEmpty) {
          finalImageUrl = uploadedFileUrl;
          print("Nueva imagen subida exitosamente: $finalImageUrl");
        } else {
          throw Exception("Error al subir la nueva imagen. El servicio de subida no devolvió una URL válida.");
        }
      }

      // Paso 3: Verificar si hay una URL de imagen final.
      if (finalImageUrl.isEmpty) {
        throw Exception("La receta debe tener una imagen.");
      }

      // Preparar los datos para Firestore
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
              decoration: _inputDecoration(context: context, label: "Nombre", icon: Icons.restaurant_menu_rounded),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
               enabled: !_isSaving, textCapitalization: TextCapitalization.sentences,
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 12),

            Text("Imagen de la Receta", style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Center(
              child: GestureDetector(
                onTap: _isSaving ? null : () {
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
                              if (_selectedImageFile != null)
                                ListTile(
                                  leading: Icon(Icons.delete_outline, color: colorScheme.error),
                                  title: Text('Quitar imagen nueva', style: TextStyle(color: colorScheme.error)),
                                  onTap: () {
                                    setState(() {
                                      _selectedImageFile = null;
                                    });
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
              decoration: _inputDecoration(context: context, label: "Descripción", icon: Icons.description_outlined),
              maxLines: 3, enabled: !_isSaving, textCapitalization: TextCapitalization.sentences,
            ).animate().fadeIn(delay: 200.ms),
             const SizedBox(height: 12),
             Row(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                  Expanded(
                     child: TextFormField(
                        controller: _tiempoController,
                        decoration: _inputDecoration(context: context, label: "Tiempo (min)", icon: Icons.timer_outlined),
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
                       decoration: _inputDecoration(context: context, label: "Categoría", icon: Icons.category_outlined),
                        enabled: !_isSaving, textCapitalization: TextCapitalization.words,
                         validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ).animate().fadeIn(delay: 350.ms),
                 ),
                 const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                       controller: _gastronomiaController,
                       decoration: _inputDecoration(context: context, label: "Gastronomía", icon: Icons.public_rounded),
                        enabled: !_isSaving, textCapitalization: TextCapitalization.words,
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
                onPressed: _isSaving ? null : _addStep,
              ),
            ),

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