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
  final List<String> pasos;
  final String? creadorId; // Nuevo campo

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
    required this.pasos,
    this.creadorId, // Añadir al constructor
  });

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
      'pasos': pasos,
      'creadorId': creadorId, // Añadir al mapa
    };
  }

  // Crea una receta desde un Map de Firestore y su ID
  factory Receta.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Receta(
      id: documentId,
      nombre: data['nombre'] ?? '',
      urlImagen: data['urlImagen'] ?? '',
      ingredientes: List<String>.from(data['ingredientes'] ?? []),
      descripcion: data['descripcion'] ?? '',
      tiempoMinutos: data['tiempoMinutos'] ?? 0,
      calificacion: data['calificacion'] ?? 0,
      nutritionalInfo: data['nutritionalInfo'],
      categoria: data['categoria'] ?? '',
      gastronomia: data['gastronomia'] ?? '',
      pasos: List<String>.from(data['pasos'] ?? []),
      creadorId: data['creadorId'] as String?, // Leer desde Firestore
    );
  }
}
