import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:recetas360/components/DetalleReceta.dart';
import 'package:recetas360/components/Receta.dart';
import 'package:recetas360/pagines/PaginaLogin.dart';
import 'firebase_options.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:google_fonts/google_fonts.dart';

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
  runApp(const MyApp());
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

  @override
  void initState() {
    super.initState();
    _initializeApplication();
  }

  Future<void> _initializeApplication() async {
    await _initDynamicLinks();
    analytics.logAppOpen();

    final prefs = await SharedPreferences.getInstance();
    final checked = prefs.getBool('checkedMigration') ?? false;
    if (!checked) {
      _launchBackgroundMigration();
      await prefs.setBool('checkedMigration', true);
    }

    if (mounted) setState(() => _isInitialized = true);
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

  Future<void> _initDynamicLinks() async {
    FirebaseDynamicLinks.instance.onLink.listen(
      (dynamicLinkData) {
        if (dynamicLinkData != null) {
          analytics.logEvent(
            name: 'dynamic_link_received',
            parameters: {'link': dynamicLinkData.link.toString()},
          );
          _handleDeepLink(dynamicLinkData.link);
        }
      },
      onError: (e) {
        analytics.logEvent(
          name: 'dynamic_link_onlink_error',
          parameters: {'error': e.toString()},
        );
      },
    );

    try {
      final initialLink = await FirebaseDynamicLinks.instance.getInitialLink();
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
    analytics.logEvent(
      name: 'handle_deep_link',
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
            if (state != null) {
              state.push(MaterialPageRoute(
                  builder: (_) => DetalleReceta(receta: receta)));
              analytics.logEvent(
                name: 'deep_link_recipe_found',
                parameters: {'recipe_id': id},
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
    final poppins = GoogleFonts.poppinsTextTheme(
      Theme.of(context).textTheme,
    );
    if (!_isInitialized) {
      return MaterialApp(
        navigatorKey: navigatorKey,
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
      themeMode: ThemeMode.system,
      home: const Paginalogin(),
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: analytics),
      ],
    );
  }
}
