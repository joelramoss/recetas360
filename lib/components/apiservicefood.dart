import 'package:recetas360/components/apiservice.dart';
import 'package:recetas360/components/nutritionalifno.dart';


import 'producto.dart';

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
