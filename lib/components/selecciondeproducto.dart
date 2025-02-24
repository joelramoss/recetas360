import 'package:flutter/material.dart';
import 'package:recetas360/components/apiservice.dart';
import 'producto.dart';

Future<Producto?> showProductoSelection(BuildContext context, String ingrediente) async {
  ApiService apiService = ApiService();
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
