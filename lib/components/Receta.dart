class Receta {
  String id;
  final String nombre;
  final String urlImagen;
  final List<String> ingredientes;
  final String descripcion;
  final int tiempoMinutos;
  int calificacion;
  final Map<String, dynamic>? nutritionalInfo;
  final String categoria;
  final String gastronomia;

  // Nuevo campo: pasos de la receta
  final List<String> pasos;

  Receta({
    this.id = '',
    required this.nombre,
    required this.urlImagen,
    required this.ingredientes,
    required this.descripcion,
    required this.tiempoMinutos,
    required this.calificacion,
    this.nutritionalInfo,
    required this.categoria,
    required this.gastronomia,
    required this.pasos, // <-- Campo obligatorio
  });

  // Convierte la receta en Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'urlImagen': urlImagen,
      'ingredientes': ingredientes,
      'descripcion': descripcion,
      'tiempoMinutos': tiempoMinutos,
      'calificacion': calificacion,
      'nutritionalInfo': nutritionalInfo,
      'categoria': categoria,
      'gastronomia': gastronomia,
      'pasos': pasos, // <-- Guardamos los pasos
    };
  }

  // Crea una receta desde un Map de Firestore
  factory Receta.fromFirestore(Map<String, dynamic> data) {
    return Receta(
      id: data['id'] ?? '',
      nombre: data['nombre'] ?? '',
      urlImagen: data['urlImagen'] ?? '',
      ingredientes: List<String>.from(data['ingredientes'] ?? []),
      descripcion: data['descripcion'] ?? '',
      tiempoMinutos: data['tiempoMinutos'] ?? 0,
      calificacion: data['calificacion'] ?? 0,
      nutritionalInfo: data['nutritionalInfo'],
      categoria: data['categoria'] ?? '',
      gastronomia: data['gastronomia'] ?? '',
      pasos: List<String>.from(data['pasos'] ?? []), // <-- Leemos los pasos
    );
  }
}
