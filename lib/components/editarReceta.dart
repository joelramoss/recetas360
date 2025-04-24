import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recetas360/components/Receta.dart';
import 'package:recetas360/components/producto.dart';
import 'package:recetas360/components/selecciondeproducto.dart'; // Assuming this is updated for M3
import 'package:recetas360/components/nutritionalifno.dart'; // Assuming this exists
import 'package:flutter_animate/flutter_animate.dart';

// Current User's Login: joelramoss
// Current Date and Time (UTC - YYYY-MM-DD HH:MM:SS formatted): 2025-04-24 14:55:03


// --- Ingredient Selection Helper Class (remains the same logic) ---
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
  const EditarReceta({Key? key, required this.receta}) : super(key: key);

  @override
  _EditarRecetaState createState() => _EditarRecetaState();
}

class _EditarRecetaState extends State<EditarReceta> {
  final _formKey = GlobalKey<FormState>();

  // --- Controllers ---
  late TextEditingController _nombreController;
  late TextEditingController _urlImagenController;
  late TextEditingController _descripcionController;
  late TextEditingController _tiempoController;
  late TextEditingController _categoriaController;
  late TextEditingController _gastronomiaController;
  List<IngredientSelection> _ingredients = [];
  List<TextEditingController> _stepControllers = [];
  double _calificacion = 3.0; // Use double for Slider

  // --- State ---
  bool _isSaving = false;
  NutritionalInfo _totalInfo = NutritionalInfo(energy: 0.0, proteins: 0.0, carbs: 0.0, fats: 0.0, saturatedFats: 0.0); // Initialize with zeros

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing recipe data
    _nombreController = TextEditingController(text: widget.receta.nombre);
    _urlImagenController = TextEditingController(text: widget.receta.urlImagen);
    _descripcionController = TextEditingController(text: widget.receta.descripcion);
    _tiempoController = TextEditingController(text: widget.receta.tiempoMinutos.toString());
    _categoriaController = TextEditingController(text: widget.receta.categoria);
    _gastronomiaController = TextEditingController(text: widget.receta.gastronomia);
    _calificacion = widget.receta.calificacion.toDouble(); // Convert int to double

    _ingredients = widget.receta.ingredientes
        .map((name) => IngredientSelection(name: name, selected: null)) // Product info needs re-fetching if needed
        .toList();
    if (_ingredients.isEmpty) _ingredients.add(IngredientSelection(name: '')); // Ensure one

    _stepControllers = widget.receta.pasos
        .map((step) => TextEditingController(text: step))
        .toList();
    if (_stepControllers.isEmpty) _stepControllers.add(TextEditingController()); // Ensure one

    // Initialize nutritional info (consider re-calculation strategy)
    if (widget.receta.nutritionalInfo != null) {
      try {
        _totalInfo = NutritionalInfo.fromMap(widget.receta.nutritionalInfo!);
      } catch (e) {
        print("Error parsing saved nutritional info: $e");
        _totalInfo = NutritionalInfo(energy: 0.0, proteins: 0.0, carbs: 0.0, fats: 0.0, saturatedFats: 0.0); // Reset on error
      }
    } else {
       _totalInfo = NutritionalInfo(energy: 0.0, proteins: 0.0, carbs: 0.0, fats: 0.0, saturatedFats: 0.0);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _urlImagenController.dispose();
    _descripcionController.dispose();
    _tiempoController.dispose();
    _categoriaController.dispose();
    _gastronomiaController.dispose();
    for (var ing in _ingredients) ing.dispose();
    for (var c in _stepControllers) c.dispose();
    super.dispose();
  }

  // --- Input Decoration Helper ---
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
      // Inherit border, fill color etc. from theme's inputDecorationTheme
      // Customize density if needed
      isDense: dense,
      contentPadding: dense ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10) : null,
    );
  }

  // --- Recalculate Macros ---
  void _recalcularMacros() {
    NutritionalInfo total = NutritionalInfo(energy: 0.0, proteins: 0.0, carbs: 0.0, fats: 0.0, saturatedFats: 0.0); // Initialize with zeros
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

  // --- Build Ingredient Row ---
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
              Producto? producto = await showProductoSelection(context, currentName); // Assumes M3 style
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

  // --- Build Step Row ---
  Widget _buildStepRow(int index, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align top for multiline
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
            // Only enable remove if more than one step exists
            onPressed: _isSaving || _stepControllers.length <= 1 ? null : () {
               setState(() => _stepControllers.removeAt(index).dispose());
            },
             visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  // --- Add Ingredient/Step ---
  void _addIngredient() => setState(() => _ingredients.add(IngredientSelection(name: '')));
  void _addStep() => setState(() => _stepControllers.add(TextEditingController()));

  // --- Section Header Helper ---
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

  // --- Update Recipe Logic ---
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

    List<String> ingredientesFinal = _ingredients.map((ing) => ing.controller.text.trim()).where((name) => name.isNotEmpty).toList();
    List<String> pasosFinal = _stepControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
    Map<String, dynamic> nutritionalMap = _totalInfo.toMap();

    try {
      final docRef = FirebaseFirestore.instance.collection('recetas').doc(widget.receta.id);

      await docRef.update({
        'nombre': _nombreController.text.trim(),
        'urlImagen': _urlImagenController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        'tiempoMinutos': int.tryParse(_tiempoController.text.trim()) ?? widget.receta.tiempoMinutos,
        'categoria': _categoriaController.text.trim(),
        'gastronomia': _gastronomiaController.text.trim(),
        'calificacion': _calificacion.round(), // Save rating as int
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
      print("Error updating recipe: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar: ${e.toString()}', style: TextStyle(color: colorScheme.onError)),
          backgroundColor: colorScheme.error,
        ),
      );
    } finally {
       if (mounted) setState(() => _isSaving = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Receta"),
        // Optional: Add a delete action here if desired
        // actions: [ IconButton(...) ]
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- Basic Info ---
            _buildSectionHeader(context, "Información Básica"),
            TextFormField(
              controller: _nombreController,
              decoration: _inputDecoration(context: context, label: "Nombre", icon: Icons.restaurant_menu_rounded),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
               enabled: !_isSaving, textCapitalization: TextCapitalization.sentences,
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 12),
            TextFormField(
              controller: _urlImagenController,
              decoration: _inputDecoration(context: context, label: "URL Imagen", icon: Icons.image_rounded),
              keyboardType: TextInputType.url, enabled: !_isSaving,
            ).animate().fadeIn(delay: 150.ms),
             const SizedBox(height: 12),
            TextFormField(
              controller: _descripcionController,
              decoration: _inputDecoration(context: context, label: "Descripción", icon: Icons.description_outlined),
              maxLines: 3, enabled: !_isSaving, textCapitalization: TextCapitalization.sentences,
            ).animate().fadeIn(delay: 200.ms),
             const SizedBox(height: 12),
             // --- Time & Rating ---
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
                           // Use theme colors automatically
                           // activeColor: colorScheme.primary,
                           // inactiveColor: colorScheme.primary.withOpacity(0.3),
                           onChanged: _isSaving ? null : (value) => setState(() => _calificacion = value),
                         ).animate().fadeIn(delay: 300.ms),
                       ],
                     ),
                  ),
               ],
             ),
            const SizedBox(height: 12),
            // --- Category & Gastronomy ---
            Row(
              children: [
                 Expanded(
                    child: TextFormField(
                       controller: _categoriaController,
                       decoration: _inputDecoration(context: context, label: "Categoría", icon: Icons.category_outlined),
                        enabled: !_isSaving, textCapitalization: TextCapitalization.words,
                    ).animate().fadeIn(delay: 350.ms),
                 ),
                 const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                       controller: _gastronomiaController,
                       decoration: _inputDecoration(context: context, label: "Gastronomía", icon: Icons.public_rounded),
                        enabled: !_isSaving, textCapitalization: TextCapitalization.words,
                    ).animate().fadeIn(delay: 400.ms),
                 ),
              ],
            ),

            // --- Ingredients ---
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

            // --- Steps ---
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

             // --- Macros ---
             _buildSectionHeader(context, "Información Nutricional (Estimada)"),
             Card( // Display macros in a card
                elevation: 0,
                color: colorScheme.secondaryContainer.withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                 child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      _totalInfo.toString(), // Use toString method from NutritionalInfo
                      style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSecondaryContainer),
                    ),
                 ),
             ).animate().fadeIn(delay: 500.ms),
             const SizedBox(height: 32),

            // --- Save Button ---
            ElevatedButton.icon(
              icon: _isSaving ? Container(width: 20, height: 20, margin: const EdgeInsets.only(right: 8), child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary)) : const Icon(Icons.save_rounded),
              label: Text(_isSaving ? 'Guardando...' : 'Guardar Cambios'),
              style: ElevatedButton.styleFrom(
                 minimumSize: const Size(double.infinity, 50), // Full width button
                 // Inherit colors from theme
              ),
              onPressed: _isSaving ? null : _updateReceta,
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.5),
          ],
        ),
      ),
    );
  }
}