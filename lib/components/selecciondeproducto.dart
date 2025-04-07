import 'package:flutter/material.dart';
import 'package:recetas360/components/apiservice.dart';
import 'producto.dart';

// Modificar para que primero cargue los productos y luego muestre el diálogo
Future<Producto?> showProductoSelection(BuildContext context, String ingrediente) async {
  // Mostrar indicador de carga inmediato con el contexto válido
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Buscando productos..."),
          ],
        ),
      );
    },
  );

  // Realizar la búsqueda
  ApiService apiService = ApiService();
  List<Producto> productos = [];
  
  try {
    productos = await apiService.buscarProductos(ingrediente);
  } catch (e) {
    // Cerrar diálogo de carga
    Navigator.of(context, rootNavigator: true).pop();
    
    // Mostrar error
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al buscar productos: $e")),
      );
    }
    return null;
  }

  // Cerrar el diálogo de carga
  Navigator.of(context, rootNavigator: true).pop();
  
  // Verificar que el contexto siga siendo válido
  if (!context.mounted) return null;
  
  // Mostrar diálogo de selección con los productos cargados
  return showDialog<Producto>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text('Selecciona el producto para "$ingrediente"'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: productos.isEmpty
              ? const Center(child: Text("No se encontraron productos"))
              : ListView.builder(
                  itemCount: productos.length,
                  itemBuilder: (_, index) {
                    final producto = productos[index];
                    return ListTile(
                      title: Text(producto.nombre),
                      subtitle: Text('Valor Energético: ${producto.valorEnergetico} kcal'),
                      onTap: () {
                        Navigator.of(dialogContext).pop(producto);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text("Cancelar"),
          ),
        ],
      );
    },
  );
}
