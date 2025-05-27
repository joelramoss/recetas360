import 'package:recetas360/components/agregarReceta.dart';
import 'Receta.dart';
import 'nutritionalifno.dart'; // Donde tienes la clase NutritionalInfo
import 'package:recetas360/services/gemini_service.dart'; // Importar GeminiService
// Ya no se necesita getRecipeNutritionalInfo aquí

Future<void> crearNuevaRecetaEjemplo() async { // Renombrado para claridad
  // Instanciar GeminiService
  final GeminiService geminiService = GeminiService();

  // Datos ingresados por el usuario (ejemplo):
  String nombre = "Ensalada Fresca Estimada";
  String urlImagen = "https://via.placeholder.com/300/FFA07A/000000?Text=Ensalada"; // URL de placeholder
  
  // Ingredientes con cantidades (IMPORTANTE para Gemini)
  List<String> ingredientesConCantidades = [
    "150g de Lechuga romana",
    "1 tomate mediano (aproximadamente 120g)",
    "50g de aceitunas verdes sin hueso",
    "30g de queso feta"
  ];
  
  String descripcion = "Ensalada con ingredientes frescos típicos del Mediterráneo, macros estimados por IA.";
  int tiempoMinutos = 15;
  int calificacion = 4;
  String categoria = "Verduras";
  String gastronomia = "Mediterranea";

  // Estimar la info nutricional con Gemini
  NutritionalInfo? infoEstimada = await geminiService.estimarMacrosDeReceta(ingredientesConCantidades);

  // Usar NutritionalInfo.zero() si la estimación falla o es nula
  NutritionalInfo infoFinal = infoEstimada ?? NutritionalInfo.zero();

  // Pasos detallados de la receta
  List<String> pasos = [
    "Lavar y secar bien la lechuga.",
    "Cortar el tomate en rodajas finas.",
    "Mezclar todos los ingredientes en un bol grande.",
    "Agregar queso feta desmenuzado y aceitunas.",
    "Aliñar con aceite de oliva virgen extra, sal y pimienta al gusto.",
  ];

  // Crear el objeto receta con toda la información
  // Nota: El constructor de Receta puede requerir más campos como id, userId, etc.
  // Para este ejemplo, asumiré que algunos tienen valores predeterminados o no son estrictamente necesarios
  // para la función 'agregarReceta' tal como la tienes. Ajusta según tu clase Receta.
  Receta nuevaReceta = Receta(
    id: '', // Firestore suele generar esto si se pasa vacío, o puedes generarlo tú
    nombre: nombre,
    urlImagen: urlImagen,
    ingredientes: ingredientesConCantidades, // Usar la lista con cantidades
    descripcion: descripcion,
    tiempoMinutos: tiempoMinutos,
    calificacion: calificacion,
    nutritionalInfo: infoFinal.toMap(), // Convierte a Map para guardar en Firestore
    categoria: categoria,
    gastronomia: gastronomia,
    pasos: pasos,
    creadorId: 'idUsuarioEjemplo', 

  );

  // Guardar en Firestore usando la función importada
  try {
    await agregarReceta(nuevaReceta);
    print("Receta de ejemplo creada y guardada exitosamente con macros estimados.");
  } catch (e) {
    print("Error al guardar la receta de ejemplo: $e");
  }
}
