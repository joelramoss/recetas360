// producto.dart
class Producto {
  final String nombre;
  final double valorEnergetico;
  final double proteinas;
  final double carbohidratos;
  final double grasas;
  final double grasasSaturadas;

  Producto({
    required this.nombre,
    required this.valorEnergetico,
    required this.proteinas,
    required this.carbohidratos,
    required this.grasas,
    required this.grasasSaturadas,
  });

  /// Función auxiliar para convertir dinámicos a double,
  /// manejando tanto String como num o null.
  static double parseDynamicToDouble(dynamic value) {
    if (value == null) {
      return 0.0;
    } else if (value is num) {
      return value.toDouble();
    } else if (value is String) {
      return double.tryParse(value) ?? 0.0;
    } else {
      return 0.0;
    }
  }

  factory Producto.fromJson(Map<String, dynamic> json) {
    final nutriments = json["nutriments"] ?? {};
    return Producto(
      nombre: json["product_name"] ?? "Sin nombre",
      valorEnergetico: parseDynamicToDouble(nutriments["energy-kcal_100g"]),
      proteinas: parseDynamicToDouble(nutriments["proteins_100g"]),
      carbohidratos: parseDynamicToDouble(nutriments["carbohydrates_100g"]),
      grasas: parseDynamicToDouble(nutriments["fat_100g"]),
      grasasSaturadas: parseDynamicToDouble(nutriments["saturated-fat_100g"]),
    );
  }
}
