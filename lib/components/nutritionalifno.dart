// recipe_nutrition_service.dart
// Ya no necesitas importar 'apiservice.dart' ni 'producto.dart' aquí
// si getRecipeNutritionalInfo se elimina.

class NutritionalInfo {
  final double energy;
  final double proteins;
  final double carbs;
  final double fats;
  final double saturatedFats;

  NutritionalInfo({
    required this.energy,
    required this.proteins,
    required this.carbs,
    required this.fats,
    required this.saturatedFats,
  });

  NutritionalInfo operator +(NutritionalInfo other) {
    return NutritionalInfo(
      energy: energy + other.energy,
      proteins: proteins + other.proteins,
      carbs: carbs + other.carbs,
      fats: fats + other.fats, // Asegúrate de sumar todos los campos
      saturatedFats: saturatedFats + other.saturatedFats,
    );
  }

  // Constructor para valores cero, útil para inicializar
  factory NutritionalInfo.zero() {
    return NutritionalInfo(
      energy: 0,
      proteins: 0,
      carbs: 0,
      fats: 0,
      saturatedFats: 0,
    );
  }

  // (Opcional) Mantener toMap y fromMap si los usas para Firestore
   Map<String, dynamic> toMap() {
    return {
      'energy': energy,
      'proteins': proteins,
      'carbs': carbs,
      'fats': fats,
      'saturatedFats': saturatedFats,
    };
  }

  factory NutritionalInfo.fromMap(Map<String, dynamic> map) {
    return NutritionalInfo(
      energy: (map['energy'] as num?)?.toDouble() ?? 0.0,
      proteins: (map['proteins'] as num?)?.toDouble() ?? 0.0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0.0,
      fats: (map['fats'] as num?)?.toDouble() ?? 0.0,
      saturatedFats: (map['saturatedFats'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// ELIMINAR LA FUNCIÓN getRecipeNutritionalInfo de aquí
/*
Future<NutritionalInfo> getRecipeNutritionalInfo(
    List<Map<String, dynamic>> ingredientsData, 
    ApiService apiService, // Ya no se pasaría ApiService
) async {
  // ... lógica anterior ...
}
*/
