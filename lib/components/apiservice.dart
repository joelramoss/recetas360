// api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'producto.dart';

class ApiService {
  final String baseUrl = "https://world.openfoodfacts.org/cgi/search.pl";
  final Map<String, List<Producto>> _cache = {};

  Future<List<Producto>> buscarProductos(String consulta, {int page = 1}) async { // Añadido parámetro page
    final String cacheKey = "${consulta.toLowerCase().trim()}:$page"; // Clave de caché incluye la página

    if (_cache.containsKey(cacheKey)) {
      print("Devolviendo desde caché para: $cacheKey");
      return _cache[cacheKey]!;
    }

    print("Llamando a la API para: $cacheKey (Página: $page)");
    final String encodedConsulta = Uri.encodeComponent(consulta);
    
    // Define los campos exactos que necesitas de la API
    // Asegúrate de que tu clase Producto pueda manejar todos estos campos.
    final String fieldsToFetch = "product_name,nutriments.energy-kcal_100g,nutriments.proteins_100g,nutriments.carbohydrates_100g,nutriments.fat_100g,nutriments.saturated-fat_100g,code,image_url,brands,quantity";

    final url = Uri.parse(
      "$baseUrl?search_terms=$encodedConsulta&action=process&json=1&page_size=5&page=$page&fields=$fieldsToFetch&search_simple=1", // Añadido page y search_simple=1
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> productosJson = data["products"] ?? [];
      final List<Producto> productos = productosJson.map((json) => Producto.fromJson(json)).toList();
      
      _cache[cacheKey] = productos;
      
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
