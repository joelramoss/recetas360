import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:recetas360/components/DetalleReceta.dart';
import 'package:recetas360/components/Receta.dart';
import 'package:recetas360/pagines/PaginaLogin.dart';
import 'firebase_options.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Verificar si la actualización ya se ha realizado
  DocumentSnapshot configDoc = await FirebaseFirestore.instance
      .collection('configuraciones')
      .doc('actualizacion_nombres')
      .get();

  bool actualizacionCompletada = configDoc.exists && configDoc.get('completada') == true;

  if (!actualizacionCompletada) {
    await actualizarNombresEnComentarios();
    // Marcar la actualización como completada
    await FirebaseFirestore.instance
        .collection('configuraciones')
        .doc('actualizacion_nombres')
        .set({'completada': true});
  }

  // Set up Google Fonts license (optional but recommended)
  GoogleFonts.config.allowRuntimeFetching = false;

  runApp(const MyApp());
}

// Método para actualizar los nombres en los comentarios
Future<void> actualizarNombresEnComentarios() async {
  try {
    QuerySnapshot recetasSnapshot =
        await FirebaseFirestore.instance.collection('recetas').get();

    WriteBatch batch = FirebaseFirestore.instance.batch();
    int batchCounter = 0;

    for (var recetaDoc in recetasSnapshot.docs) {
      QuerySnapshot comentariosSnapshot = await recetaDoc.reference
          .collection('comentarios')
          .get();

      for (var comentarioDoc in comentariosSnapshot.docs) {
        final data = comentarioDoc.data() as Map<String, dynamic>?;

        if (data != null && data.containsKey('usuarioId') && (!data.containsKey('usuarioNombre') || data['usuarioNombre'] == 'Usuario desconocido')) {
          String usuarioId = data['usuarioId'];
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(usuarioId)
              .get();

          if (userDoc.exists) {
            String nombreUsuario = (userDoc.data() as Map<String, dynamic>?)?['nombre'] ?? 'Usuario desconocido';
            batch.update(comentarioDoc.reference, {'usuarioNombre': nombreUsuario});
            batchCounter++;

            if (batchCounter >= 400) {
              await batch.commit();
              batch = FirebaseFirestore.instance.batch();
              batchCounter = 0;
            }
          } else {
            batch.update(comentarioDoc.reference, {'usuarioNombre': 'Usuario eliminado'});
            batchCounter++;
            if (batchCounter >= 400) {
              await batch.commit();
              batch = FirebaseFirestore.instance.batch();
              batchCounter = 0;
            }
          }
        } else if (data == null || !data.containsKey('usuarioId')) {
          print('Comentario sin usuarioId o data null: ${comentarioDoc.id} en receta ${recetaDoc.id}');
        }
      }
    }

    if (batchCounter > 0) {
      await batch.commit();
    }

    print('Actualización de nombres en comentarios completada.');
  } catch (e) {
    print('Error al actualizar nombres en comentarios: $e');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _initDynamicLinks();
  }

  Future<void> _initDynamicLinks() async {
    FirebaseDynamicLinks.instance.onLink.listen((PendingDynamicLinkData? dynamicLinkData) {
      if (dynamicLinkData != null) {
        _handleDeepLink(dynamicLinkData.link);
      }
    }).onError((error) {
      print('Error en onLink de Dynamic Links: $error');
    });

    final PendingDynamicLinkData? initialLink = await FirebaseDynamicLinks.instance.getInitialLink();
    if (initialLink != null) {
      _handleDeepLink(initialLink.link);
    }
  }

  void _handleDeepLink(Uri deepLink) async {
    print("Deep Link recibido: $deepLink");
    if (deepLink.pathSegments.contains('receta')) {
      final String? recipeId = deepLink.queryParameters['id'];
      if (recipeId != null && recipeId.isNotEmpty) {
        print("Navegando a la receta con ID: $recipeId");
        try {
          DocumentSnapshot recipeDoc = await FirebaseFirestore.instance.collection('recetas').doc(recipeId).get();
          if (recipeDoc.exists && recipeDoc.data() != null) {
            final receta = Receta.fromFirestore(recipeDoc.data() as Map<String, dynamic>, recipeDoc.id);
            navigatorKey.currentState?.push(MaterialPageRoute(
              builder: (_) => DetalleReceta(receta: receta),
            ));
          } else {
            print("Receta con ID $recipeId no encontrada.");
          }
        } catch (e) {
          print("Error al cargar la receta desde el deep link: $e");
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final poppinsTextTheme = GoogleFonts.poppinsTextTheme(textTheme);

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Recetas360',
      theme: FlexThemeData.light(
        scheme: FlexScheme.mango,
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 7,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 10,
          blendOnColors: false,
          useTextTheme: true,
          useM2StyleDividerInM3: true,
          alignedDropdown: true,
          useInputDecoratorThemeInDialogs: true,
          inputDecoratorRadius: 20.0,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
        swapLegacyOnMaterial3: true,
        textTheme: poppinsTextTheme,
        primaryTextTheme: poppinsTextTheme,
      ),
      darkTheme: FlexThemeData.dark(
        scheme: FlexScheme.mango,
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 13,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 20,
          useTextTheme: true,
          useM2StyleDividerInM3: true,
          alignedDropdown: true,
          useInputDecoratorThemeInDialogs: true,
          inputDecoratorRadius: 20.0,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
        swapLegacyOnMaterial3: true,
        textTheme: poppinsTextTheme,
        primaryTextTheme: poppinsTextTheme,
      ),
      themeMode: ThemeMode.system,
      home: const Paginalogin(),
    );
  }
}