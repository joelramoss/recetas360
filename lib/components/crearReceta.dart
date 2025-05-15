import 'package:recetas360/components/agregarReceta.dart';
import 'Receta.dart';
import 'nutritionalifno.dart'; // Donde tienes la clase NutritionalInfo y getRecipeNutritionalInfo
// Aquí se encuentra getRecipeNutritionalInfo


Future<void> crearNuevaReceta() async {
  // Datos ingresados por el usuario:
  String nombre = "Ensalada Fresca";
  String urlImagen = "https://via.placeholder.com/150";
  List<String> ingredientes = ["Lechuga", "Tomate", "Aceitunas", "Queso feta"];
  String descripcion = "Ensalada con ingredientes frescos tipicos del Mediterranea.";
  int tiempoMinutos = 15;
  int calificacion = 4;
  String categoria = "Verduras"; // Por ejemplo
  String gastronomia = "Mediterranea"; // Sin acento

  // Calcular la info nutricional (esto puede tardar un poco)
  NutritionalInfo info = await getRecipeNutritionalInfo(ingredientes);

  // Pasos detallados de la receta
  List<String> pasos = [
    "Lavar y secar bien la lechuga.",
    "Cortar el tomate en rodajas finas.",
    "Mezclar todos los ingredientes en un bol grande.",
    "Agregar queso feta desmenuzado y aceitunas.",
    "Aliñar con aceite de oliva, sal y pimienta al gusto.",
  ];

  // Crear el objeto receta con toda la información, incluyendo 'pasos' y 'nutritionalInfo'
  Receta nuevaReceta = Receta(
    nombre: nombre,
    urlImagen: urlImagen,
    ingredientes: ingredientes,
    descripcion: descripcion,
    tiempoMinutos: tiempoMinutos,
    calificacion: calificacion,
    nutritionalInfo: info.toMap(), // Convierte a Map para guardar en Firestore
    categoria: categoria,
    gastronomia: gastronomia,
    pasos: pasos, // Nuevo campo pasos
  );

  // Guardar en Firestore usando la función importada
  await agregarReceta(nuevaReceta);
}
