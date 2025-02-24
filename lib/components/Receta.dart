class Receta {
  final String nombre;
  final String urlImagen;
  final List<String> ingredientes;
  final String descripcion;
  final int tiempoMinutos;
  int calificacion; // Cambié 'final' a 'int' para que sea mutable

  Receta({
    required this.nombre,
    required this.urlImagen,
    required this.ingredientes,
    required this.descripcion,
    required this.tiempoMinutos,
    required this.calificacion, // Asegúrate de pasar un valor al crear la receta
  });
}
