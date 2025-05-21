import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:recetas360/components/DetalleReceta.dart';
import 'package:recetas360/components/Receta.dart';
import 'package:recetas360/pagines/PaginaLogin.dart';
import 'firebase_options.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recetas360/FirebaseServices.dart'; // Importar FirebaseService

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  GoogleFonts.config.allowRuntimeFetching = false;

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  bool _isInitialized = false;
  final FirebaseService _firebaseService = FirebaseService(); // Instancia

  @override
  void initState() {
    super.initState();
    _initializeApplication();
  }

  Future<void> _initializeApplication() async {
    await _initDynamicLinks();
    analytics.logAppOpen();

    _lanzarActualizacionComentariosEnSegundoPlano();

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _lanzarActualizacionComentariosEnSegundoPlano() async {
    try {
      DocumentSnapshot configDoc = await FirebaseFirestore.instance
          .collection('configuraciones')
          .doc('actualizacion_nombres')
          .get();

      bool actualizacionCompletada =
          configDoc.exists && configDoc.get('completada') == true;

      if (!actualizacionCompletada) {
        print(
            "Iniciando actualización de nombres en comentarios en segundo plano (llamando a FirebaseService)...");
        _firebaseService.actualizarNombresEnComentariosGlobal().catchError((error) {
          print("Error en actualización de nombres en segundo plano (desde main): $error");
          analytics.logEvent(
            name: 'error_actualizar_comentarios_background_main',
            parameters: {'error': error.toString()},
          );
        });
      } else {
        print(
            "La actualización de nombres en comentarios ya fue completada previamente.");
      }
    } catch (e) {
      print("Error al verificar estado de actualización de comentarios: $e");
      analytics.logEvent(
        name: 'error_verificar_actualizacion_comentarios',
        parameters: {'error': e.toString()},
      );
    }
  }

  Future<void> _initDynamicLinks() async {
    FirebaseDynamicLinks.instance.onLink.listen(
      (PendingDynamicLinkData? dynamicLinkData) {
        if (dynamicLinkData != null) {
          analytics.logEvent(
            name: 'dynamic_link_received',
            parameters: {'link': dynamicLinkData.link.toString()},
          );
          _handleDeepLink(dynamicLinkData.link);
        }
      },
      onError: (error) {
        print('Error en onLink de Dynamic Links: $error');
        analytics.logEvent(
          name: 'dynamic_link_onlink_error',
          parameters: {'error': error.toString()},
        );
      },
    );

    try {
      final PendingDynamicLinkData? initialLink =
          await FirebaseDynamicLinks.instance.getInitialLink();
      if (initialLink != null) {
        analytics.logEvent(
          name: 'dynamic_link_initial_received',
          parameters: {'link': initialLink.link.toString()},
        );
        _handleDeepLink(initialLink.link);
      } else {
        analytics.logEvent(name: 'dynamic_link_initial_null');
      }
    } catch (e) {
      print('Error al obtener initialLink de Dynamic Links: $e');
      analytics.logEvent(
        name: 'dynamic_link_initial_error',
        parameters: {'error': e.toString()},
      );
    }
  }

  void _handleDeepLink(Uri deepLink) async {
    if (!_isInitialized) {
      await Future.delayed(const Duration(milliseconds: 500));
    }

    print("Deep Link recibido: $deepLink");
    analytics.logEvent(
      name: 'handle_deep_link',
      parameters: {'link': deepLink.toString()},
    );
    if (deepLink.pathSegments.contains('receta')) {
      final String? recipeId = deepLink.queryParameters['id'];
      if (recipeId != null && recipeId.isNotEmpty) {
        print("Navegando a la receta con ID: $recipeId");
        analytics.logEvent(
          name: 'deep_link_navigate_recipe',
          parameters: {'recipe_id': recipeId},
        );
        try {
          DocumentSnapshot recipeDoc = await FirebaseFirestore.instance
              .collection('recetas')
              .doc(recipeId)
              .get();
          if (recipeDoc.exists && recipeDoc.data() != null) {
            final receta = Receta.fromFirestore(
                recipeDoc.data() as Map<String, dynamic>, recipeDoc.id);
            if (navigatorKey.currentState != null) {
              navigatorKey.currentState?.push(MaterialPageRoute(
                builder: (_) => DetalleReceta(receta: receta),
              ));
              analytics.logEvent(
                name: 'deep_link_recipe_found',
                parameters: {'recipe_id': recipeId},
              );
            } else {
              print(
                  "Error: navigatorKey.currentState es null al intentar navegar por deep link.");
              analytics.logEvent(
                name: 'deep_link_navigator_null',
                parameters: {'recipe_id': recipeId},
              );
            }
          } else {
            print("Receta con ID $recipeId no encontrada.");
            analytics.logEvent(
              name: 'deep_link_recipe_not_found',
              parameters: {'recipe_id': recipeId},
            );
          }
        } catch (e) {
          print("Error al cargar la receta desde el deep link: $e");
          analytics.logEvent(
            name: 'deep_link_recipe_load_error',
            parameters: {'recipe_id': recipeId, 'error': e.toString()},
          );
        }
      } else {
        analytics.logEvent(
          name: 'deep_link_recipe_id_missing',
          parameters: {'link': deepLink.toString()},
        );
      }
    } else {
      analytics.logEvent(
        name: 'deep_link_path_not_receta',
        parameters: {'link': deepLink.toString()},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final poppinsTextTheme = GoogleFonts.poppinsTextTheme(textTheme);

    if (!_isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

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
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: analytics),
      ],
    );
  }
}