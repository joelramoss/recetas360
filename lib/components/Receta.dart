import 'package:recetas360/components/producto.dart';

class Receta {
  final String nombre;
  final String urlImagen;
  final List<String> ingredientes;
  final String descripcion;
  final int tiempoMinutos;

  // Agrega un Map para almacenar la selección del producto de cada ingrediente
  // La clave es el nombre del ingrediente y el valor es el objeto Producto seleccionado.
  Map<String, Producto>? productosSeleccionados;

  Receta({
    required this.nombre,
    required this.urlImagen,
    required this.ingredientes,
    required this.descripcion,
    required this.tiempoMinutos,
    this.productosSeleccionados,
  });
}
