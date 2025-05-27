import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:recetas360/components/nutritionalifno.dart'; // Asegúrate que la ruta es correcta
import 'package:flutter/foundation.dart';

class GeminiService {
  late final GenerativeModel _model;
  bool _isInitialized = false;

  GeminiService() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await dotenv.load(fileName: ".env"); // Carga el .env
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        if (kDebugMode) {
          print('Error: GEMINI_API_KEY no encontrada en .env');
        }
        throw Exception('GEMINI_API_KEY no encontrada en .env');
      }
      _model = GenerativeModel(model: 'gemini-2.5-flash-preview-04-17', apiKey: apiKey); // O el modelo que prefieras/tengas acceso
      _isInitialized = true;
      if (kDebugMode) {
        print('GeminiService inicializado correctamente.');
      }
    } catch (e) {
      _isInitialized = false;
      if (kDebugMode) {
        print('Error al inicializar GeminiService: $e');
      }
      // Puedes decidir si relanzar la excepción o manejarla de otra forma
      // throw Exception('Error al inicializar GeminiService: $e');
    }
  }

  Future<NutritionalInfo?> estimarMacrosDeReceta(List<String> ingredientesConCantidades) async {
    if (!_isInitialized) {
      if (kDebugMode) {
        print('Error: GeminiService no está inicializado.');
      }
      await _initialize(); 
      if (!_isInitialized) return null;
    }
    if (ingredientesConCantidades.isEmpty) {
      // Devuelve NutritionalInfo.zero() directamente para consistencia
      return NutritionalInfo.zero();
    }

    final promptBuffer = StringBuffer();

    // --- INICIO DEL NUEVO PROMPT MEJORADO (EN INGLÉS) ---
    promptBuffer.writeln("You are a nutritional analysis assistant.");
    promptBuffer.writeln("Your task is to estimate the total macronutrients for a recipe based on the list of ingredients and their quantities provided below.");
    promptBuffer.writeln("The recipe consists of the following ingredients:");
    for (String ingrediente in ingredientesConCantidades) {
      promptBuffer.writeln("- $ingrediente");
    }

    promptBuffer.writeln("\nIMPORTANT INSTRUCTIONS FOR THE RESPONSE FORMAT:");
    promptBuffer.writeln("1. Your response MUST be ONLY a single, valid JSON object.");
    promptBuffer.writeln("2. Do NOT include any explanatory text, comments, or markdown formatting (like ```json ... ```) before or after the JSON object. The response must start with '{' and end with '}'.");
    
    promptBuffer.writeln("\nThe JSON object must follow this exact structure and use these exact keys:");
    promptBuffer.writeln("{");
    promptBuffer.writeln("  \"calorias\": <numeric_value_kcal>,");
    promptBuffer.writeln("  \"proteinas\": <numeric_value_grams>,");
    promptBuffer.writeln("  \"carbohidratos\": <numeric_value_grams>,");
    promptBuffer.writeln("  \"grasas_totales\": <numeric_value_grams>,");
    promptBuffer.writeln("  \"grasas_saturadas\": <numeric_value_grams>");
    promptBuffer.writeln("}");

    promptBuffer.writeln("\nDetails for the JSON values:");
    promptBuffer.writeln("- \"calorias\": Total estimated kilocalories (kcal) for the entire recipe. Must be a numeric value (integer or double).");
    promptBuffer.writeln("- \"proteinas\": Total estimated proteins in grams (g) for the entire recipe. Must be a numeric value (integer or double).");
    promptBuffer.writeln("- \"carbohidratos\": Total estimated carbohydrates in grams (g) for the entire recipe. Must be a numeric value (integer or double).");
    promptBuffer.writeln("- \"grasas_totales\": Total estimated total fats in grams (g) for the entire recipe. Must be a numeric value (integer or double).");
    promptBuffer.writeln("- \"grasas_saturadas\": Total estimated saturated fats in grams (g) for the entire recipe. Must be a numeric value (integer or double).");

    promptBuffer.writeln("\nAdditional rules:");
    promptBuffer.writeln("- All values in the JSON must be numeric (e.g., 250, 15.5). Do NOT include units (like \"g\" or \"kcal\") within the numeric values themselves.");
    promptBuffer.writeln("- If a specific nutrient cannot be reliably estimated from the provided ingredients, use the numeric value 0.0 for that field.");
    promptBuffer.writeln("- Ensure all keys are lowercase and exactly as specified (e.g., \"calorias\", \"proteinas\").");
    // --- FIN DEL NUEVO PROMPT MEJORADO ---

    if (kDebugMode) {
      print("Enviando prompt a Gemini:\n${promptBuffer.toString()}");
    }

    try {
      final content = [Content.text(promptBuffer.toString())];
      // Considerar ajustar los safetySettings si es necesario, aunque para esta tarea no debería ser un problema.
      // final safetySettings = [
      //   SafetySetting(HarmCategory.harassment, HarmBlockThreshold.high),
      //   SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.high),
      // ];
      // final response = await _model.generateContent(content, safetySettings: safetySettings);
      final response = await _model.generateContent(content);


      if (response.text != null) {
        if (kDebugMode) {
          print("Respuesta de Gemini (texto crudo): ${response.text}");
        }
        return _parseRespuestaGemini(response.text!);
      } else {
        if (kDebugMode) {
          print('Error: La respuesta de Gemini no contiene texto.');
          if (response.promptFeedback != null) {
            print('Prompt Feedback: ${response.promptFeedback}');
          }
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al llamar a la API de Gemini: $e');
        if (e is GenerativeAIException) {
          print('Detalle de GenerativeAIException: ${e.message}');
        }
      }
      return null;
    }
  }

  NutritionalInfo? _parseRespuestaGemini(String respuestaTexto) {
    try {
      // El prompt ahora es más estricto pidiendo JSON directo,
      // pero mantenemos el regex por si acaso el modelo aún añade markdown.
      final jsonRegex = RegExp(r'```json\s*([\s\S]*?)\s*```|({[\s\S]*})');
      final match = jsonRegex.firstMatch(respuestaTexto.trim()); // .trim() para quitar espacios/newlines

      if (match == null) {
        if (kDebugMode) {
          print('Error de parseo: No se encontró JSON en la respuesta de Gemini.');
          print('Respuesta recibida: $respuestaTexto');
        }
        return null;
      }
      
      final jsonString = match.group(1) ?? match.group(2);
      if (jsonString == null) {
         if (kDebugMode) {
          print('Error de parseo: jsonString es null después del regex.');
        }
        return null;
      }

      final Map<String, dynamic> json = jsonDecode(jsonString);
      
      double parseDouble(dynamic value) {
        if (value is num) {
          return value.toDouble();
        }
        if (value is String) {
          return double.tryParse(value) ?? 0.0;
        }
        return 0.0;
      }

      return NutritionalInfo(
        energy: parseDouble(json['calorias']),
        proteins: parseDouble(json['proteinas']),
        carbs: parseDouble(json['carbohidratos']),
        fats: parseDouble(json['grasas_totales']),
        saturatedFats: parseDouble(json['grasas_saturadas']),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error al parsear la respuesta JSON de Gemini: $e');
        print('Respuesta recibida que causó el error: $respuestaTexto');
      }
      return null;
    }
  }
}