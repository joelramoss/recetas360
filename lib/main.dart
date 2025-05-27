import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:shared_preferences/shared_preferences.dart';
import 'package:recetas360/components/DetalleReceta.dart';
import 'package:recetas360/components/Receta.dart';
import 'package:recetas360/pagines/PaginaLogin.dart';
import 'package:recetas360/serveis/ThemeNotifier.dart'; // Importa tu ThemeNotifier
import 'firebase_options.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/scheduler.dart'; // Importar SchedulerBinding

/// Constantes de colecciones y documentos
class FirebaseConstants {
  static const configCollection = 'configuraciones';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(), // Modificado: sin argumento
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final navigatorKey = GlobalKey<NavigatorState>();
  final analytics = FirebaseAnalytics.instance;
  final functions = FirebaseFunctions.instance;
  bool _isInitialized = false;
  PendingDynamicLinkData? _initialLinkData; // Para almacenar el enlace inicial

  @override
  void initState() {
    super.initState();
    _initializeApplication();
  }

  Future<void> _initializeApplication() async {
    // 1. Configurar el listener para enlaces cuando la app ya está abierta o en segundo plano
    FirebaseDynamicLinks.instance.onLink.listen(
      (dynamicLinkData) {
        if (dynamicLinkData != null) {
          analytics.logEvent(
            name: 'dynamic_link_received_active_app',
            parameters: {'link': dynamicLinkData.link.toString()},
          );
          // Usar addPostFrameCallback para manejar el enlace después de que el frame actual se complete
          // Esto es útil si la app está activa y la UI podría estar en transición.
          SchedulerBinding.instance.addPostFrameCallback((_) {
            _handleDeepLink(dynamicLinkData.link);
          });
        }
      },
      onError: (e) {
        analytics.logEvent(
          name: 'dynamic_link_onlink_error',
          parameters: {'error': e.toString()},
        );
      },
    );

    analytics.logAppOpen();

    final prefs = await SharedPreferences.getInstance();
    final checked = prefs.getBool('checkedMigration') ?? false;
    if (!checked) {
      _launchBackgroundMigration();
      await prefs.setBool('checkedMigration', true);
    }

    // 2. Obtener el enlace inicial (si la app se abrió desde uno)
    // Hacemos esto ANTES de marcar _isInitialized = true, pero lo procesaremos DESPUÉS.
    try {
      _initialLinkData = await FirebaseDynamicLinks.instance.getInitialLink();
      if (_initialLinkData != null) {
        analytics.logEvent(
          name: 'dynamic_link_initial_captured',
          parameters: {'link': _initialLinkData!.link.toString()},
        );
      } else {
        analytics.logEvent(name: 'dynamic_link_initial_null_captured');
      }
    } catch (e) {
      analytics.logEvent(
        name: 'dynamic_link_initial_capture_error',
        parameters: {'error': e.toString()},
      );
    }

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _launchBackgroundMigration() async {
    try {
      final configDoc = await FirebaseFirestore.instance
          .collection(FirebaseConstants.configCollection)
          .doc('actualizacion_nombres')
          .get();
      final done = configDoc.data()?['completada'] == true;
      if (!done) {
        final ctx = navigatorKey.currentContext;
        if (ctx != null) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Text('Actualizando comentarios en segundo plano...'),
            ),
          );
        }
        final callable = functions.httpsCallable('migrateAllCommentUserNames');
        final result = await callable();
        analytics.logEvent(
          name: 'migration_complete',
          parameters:
              Map<String, Object>.from(result.data as Map<String, dynamic>),
        );
      }
    } catch (e) {
      analytics.logEvent(
        name: 'error_migration_main',
        parameters: {'error': e.toString()},
      );
    }
  }

  // _initDynamicLinks ya no es necesaria como función separada con esta estructura.

  void _handleDeepLink(Uri deepLink) async {
    // Esta función ahora se llama cuando es seguro navegar.
    analytics.logEvent(
      name: 'handle_deep_link_invoked',
      parameters: {'link': deepLink.toString()},
    );
    if (deepLink.pathSegments.contains('receta')) {
      final id = deepLink.queryParameters['id'];
      if (id != null && id.isNotEmpty) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('recetas')
              .doc(id)
              .get();
          if (doc.exists) {
            final receta = Receta.fromFirestore(
                doc.data()! as Map<String, dynamic>, doc.id);
            final state = navigatorKey.currentState;
            if (state != null && state.mounted) { // Comprobar si el navigator está montado
              state.push(MaterialPageRoute(
                  builder: (_) => DetalleReceta(receta: receta)));
              analytics.logEvent(
                name: 'deep_link_recipe_found_navigated',
                parameters: {'recipe_id': id},
              );
            } else {
              analytics.logEvent(
                name: 'deep_link_navigator_not_ready',
                parameters: {'recipe_id': id, 'state_null': state == null, 'state_mounted': state?.mounted ?? false},
              );
            }
          } else {
            analytics.logEvent(
              name: 'deep_link_recipe_not_found',
              parameters: {'recipe_id': id},
            );
          }
        } catch (e) {
          analytics.logEvent(
            name: 'deep_link_recipe_load_error',
            parameters: {'error': e.toString()},
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final poppins = GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme);

    if (!_isInitialized) {
      return MaterialApp(
        navigatorKey: navigatorKey, // Es importante tener el navigatorKey aquí también
        debugShowCheckedModeBanner: false,
        home: const Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        ),
      );
    }

    // 3. Procesar el enlace inicial DESPUÉS de que _isInitialized es true y la UI principal se construye.
    if (_initialLinkData != null) {
      // Usar addPostFrameCallback para asegurar que el primer frame del MaterialApp principal esté construido.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (_initialLinkData != null) { // Doble chequeo por si acaso
           _handleDeepLink(_initialLinkData!.link);
          _initialLinkData = null; // Limpiar para que no se procese de nuevo en reconstrucciones.
        }
      });
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
        textTheme: poppins,
        primaryTextTheme: poppins,
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
        textTheme: poppins,
        primaryTextTheme: poppins,
      ),
      themeMode: themeNotifier.themeMode, 
      home: const Paginalogin(),
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: analytics),
      ],
    );
  }
}
