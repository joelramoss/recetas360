// recipe_nutrition_service.dart
import 'package:recetas360/components/apiservice.dart';

import 'producto.dart';

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

  // Permite sumar dos objetos de NutritionalInfo
  NutritionalInfo operator +(NutritionalInfo other) {
    return NutritionalInfo(
      energy: energy + other.energy,
      proteins: proteins + other.proteins,
      carbs: carbs + other.carbs,
      fats: fats + other.fats,
      saturatedFats: saturatedFats + other.saturatedFats,
    );
  }
}

Future<NutritionalInfo> getRecipeNutritionalInfo(List<String> ingredientes) async {
  NutritionalInfo total = NutritionalInfo(
    energy: 0,
    proteins: 0,
    carbs: 0,
    fats: 0,
    saturatedFats: 0,
  );
  ApiService apiService = ApiService();

  // Para cada ingrediente se realiza la consulta a la API
  for (String ing in ingredientes) {
    try {
      List<Producto> productos = await apiService.buscarProductos(ing);
      if (productos.isNotEmpty) {
        // Se utiliza el primer resultado como referencia
        Producto p = productos.first;
        total = total +
            NutritionalInfo(
              energy: p.valorEnergetico,
              proteins: p.proteinas,
              carbs: p.carbohidratos,
              fats: p.grasas,
              saturatedFats: p.grasasSaturadas,
            );
      }
    } catch (e) {
      // Si ocurre un error con algún ingrediente, se continúa con el siguiente
      print("Error al obtener datos para $ing: $e");
    }
  }
  return total;
}
