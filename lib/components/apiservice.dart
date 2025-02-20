// api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'producto.dart';

class ApiService {
  final String baseUrl = "https://world.openfoodfacts.org/cgi/search.pl";

  Future<List<Producto>> buscarProductos(String consulta) async {
    final url = Uri.parse(
      "$baseUrl?search_terms=$consulta&search_simple=1&action=process&json=1&page_size=50",
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> productosJson = data["products"] ?? [];
      return productosJson.map((json) => Producto.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar datos: ${response.statusCode}');
    }
  }
}
