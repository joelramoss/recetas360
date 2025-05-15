import 'package:flutter/material.dart';
import 'package:recetas360/components/apiservice.dart'; // Assuming ApiService exists
import 'producto.dart'; // Assuming Producto exists
import 'package:flutter_animate/flutter_animate.dart'; // Import animate

// Current User's Login: joelramoss
// Current Date and Time (UTC - YYYY-MM-DD HH:MM:SS formatted): 2025-04-24 14:46:00

// Function to show product selection dialog with M3 styling
Future<Producto?> showProductoSelection(BuildContext context, String ingrediente) async {
  // Get theme data for styling
  final colorScheme = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;

  // --- Show Loading Dialog ---
  showDialog(
    context: context,
    barrierDismissible: false, // User cannot dismiss by tapping outside
    builder: (BuildContext dialogContext) {
      // Use a simple Dialog for loading indicator
      return Dialog(
        backgroundColor: colorScheme.surfaceContainerHighest, // Use a theme background color
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), // M3 Dialog shape
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: colorScheme.primary), // Themed indicator
              const SizedBox(height: 20),
              Text(
                "Buscando productos...",
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    },
  );

  // --- Perform API Search ---
  final ApiService apiService = ApiService();
  List<Producto> productos = [];
  String? errorMessage;

  try {
    productos = await apiService.buscarProductos(ingrediente);
  } catch (e) {
     print("Error searching products: $e"); // Log the error
     errorMessage = "Error al buscar productos: ${e.toString()}";
  }

  // --- Close Loading Dialog ---
  // Ensure context is still valid before popping
  if (context.mounted) {
     // Use rootNavigator: true if the loading dialog might be on top of everything
    Navigator.of(context, rootNavigator: true).pop();
  }

  // --- Show Error (if any) ---
  if (errorMessage != null) {
    if (context.mounted) { // Check context again
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage, style: TextStyle(color: colorScheme.onError)),
          backgroundColor: colorScheme.error,
        ),
      );
    }
    return null; // Return null on error
  }

  // --- Show Selection Dialog (if context still valid) ---
  if (!context.mounted) return null;

  return showDialog<Producto>(
    context: context,
    builder: (BuildContext dialogContext) {
      // AlertDialog adapts to M3 automatically
      return AlertDialog(
        // Optional: Customize shape if needed, default is usually good
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        // Use titleTextStyle from theme
        title: Text('Selecciona para "$ingrediente"'),
        // Constrain content size and use themed list
        content: SizedBox(
          width: double.maxFinite, // Take available width
          height: 300, // Fixed height for the list area
          child: productos.isEmpty
              ? Center(
                  child: Column( // Center icon and text
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       Icon(Icons.search_off_rounded, size: 48, color: colorScheme.secondary),
                       const SizedBox(height: 16),
                       Text(
                         "No se encontraron productos",
                         textAlign: TextAlign.center,
                         style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                       ),
                     ],
                  )
                )
              : ListView.builder(
                  shrinkWrap: true, // Important inside SizedBox
                  itemCount: productos.length,
                  itemBuilder: (_, index) {
                    final producto = productos[index];
                    // Themed ListTile
                    return ListTile(
                       contentPadding: const EdgeInsets.symmetric(horizontal: 8.0), // Adjust padding
                       title: Text(producto.nombre, style: textTheme.bodyLarge),
                       subtitle: Text(
                         // Format nutritional info more clearly
                         '${producto.valorEnergetico.toStringAsFixed(0)} kcal, ${producto.proteinas.toStringAsFixed(1)}g P, ${producto.carbohidratos.toStringAsFixed(1)}g C, ${producto.grasas.toStringAsFixed(1)}g G',
                         style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                       ),
                       onTap: () {
                         Navigator.of(dialogContext).pop(producto); // Return selected product
                       },
                    ).animate().fadeIn(delay: (50 * index).ms); // Animate list items
                  },
                ),
        ),
        actions: [
          // Themed TextButton
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(), // Return null (cancel)
            child: const Text("Cancelar"), // Text color uses theme default
          ),
        ],
      );
    },
  );
}