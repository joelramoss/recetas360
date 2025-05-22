// api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'producto.dart';

class ApiService {
  final String baseUrl = "https://world.openfoodfacts.org/cgi/search.pl";
  // Caché en memoria simple (opcional, como se discutió antes)
  final Map<String, List<Producto>> _cache = {};

  Future<List<Producto>> buscarProductos(String consulta) async {
    final String cacheKey = consulta.toLowerCase().trim();

    if (_cache.containsKey(cacheKey)) {
      print("Devolviendo desde caché para: $cacheKey");
      return _cache[cacheKey]!;
    }

    print("Llamando a la API para: $cacheKey");
    final String encodedConsulta = Uri.encodeComponent(consulta);
    
    // Define los campos exactos que necesitas de la API
    final String fieldsToFetch = "product_name,nutriments.energy-kcal_100g,nutriments.proteins_100g,nutriments.carbohydrates_100g,nutriments.fat_100g,nutriments.saturated-fat_100g";
    // Nota: La API de Open Food Facts puede requerir que solicites el objeto 'nutriments' completo
    // y luego extraigas los subcampos, o puede permitir especificar subcampos directamente.
    // La forma más segura y común es solicitar 'nutriments' y luego procesarlo.
    // Si la especificación directa de subcampos de nutriments no funciona, usa:
    // final String fieldsToFetch = "product_name,nutriments";

    final url = Uri.parse(
      "$baseUrl?search_terms=$encodedConsulta&action=process&json=1&page_size=10&fields=$fieldsToFetch",
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> productosJson = data["products"] ?? [];
      final List<Producto> productos = productosJson.map((json) => Producto.fromJson(json)).toList();
      
      _cache[cacheKey] = productos; // Guardar en caché
      
      return productos;
    } else {
      throw Exception('Error al cargar datos: ${response.statusCode}');
    }
  }

  void limpiarCache() {
    _cache.clear();
    print("Caché de productos limpiado.");
  }
}
