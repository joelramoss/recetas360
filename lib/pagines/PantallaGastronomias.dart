import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:recetas360/components/ListaRecetas.dart'; // Asegúrate que esta ruta es correcta
import 'package:recetas360/pagines/InterfazAjustes.dart';
import 'package:recetas360/pagines/HistorialRecetas.dart';
// Asegúrate que la ruta a Burbujawidget sea correcta
import '../widgetsutilizados/burbujaestilo.dart'; // O '../widgetsutilizados/Burbujawidget.dart' si lo renombraste
import 'package:flutter_animate/flutter_animate.dart';

// Current User's Login: joelramoss
// Current Date and Time (UTC - YYYY-MM-DD HH:MM:SS formatted): 2025-04-24 15:18:52

class PantallaGastronomias extends StatefulWidget {
  final String tipoAlimento;
  const PantallaGastronomias({Key? key, required this.tipoAlimento})
      : super(key: key);

  @override
  State<PantallaGastronomias> createState() => _PantallaGastronomiasState();
}

class _PantallaGastronomiasState extends State<PantallaGastronomias>
    with SingleTickerProviderStateMixin {
  // Ajusta esta lista si es necesario basándose en tus valores de Firestore
  final List<String> subcategorias = [
    "Mediterranea",
    "Asiatica",
    "Americana",
    "Africana",
    "Oceanica"
    // Añade más si aplica
  ];

  // TODO: Añade URLs de imágenes relevantes para cada gastronomía si lo deseas
  final Map<String, String?> subcategoriasImagenes = {
    "Mediterranea":
        "https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=150&q=80", // Ejemplo
    "Asiatica":
        "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=150&q=80", // Ejemplo
    "Americana":
        "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=150&q=80", // Ejemplo
    "Africana":
        "https://images.unsplash.com/photo-1534790566855-4cb788d389ec?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=150&q=80", // Ejemplo
    "Oceanica":
        "https://images.unsplash.com/photo-1506084868230-bb9d95c24759?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=150&q=80", // Ejemplo
  };

  late AnimationController _controller;
  late List<Animation<double>> _bubbleAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration:
          const Duration(milliseconds: 1500), // Duración animación consistente
    );
    _initializeAnimations();
    _controller.forward();
  }

  // Inicializa animaciones con intervalos escalonados
  void _initializeAnimations() {
    final int n = subcategorias.length;
    if (n == 0) {
      // Evita división por cero si la lista está vacía
      _bubbleAnimations = [];
      return;
    }
    final double intervalLength = 0.6 / n;
    final double startOffset = 0.1;

    _bubbleAnimations = List.generate(n, (i) {
      double start = startOffset + (i * intervalLength * 0.8);
      double end = start + intervalLength;
      end = math.min(end, 1.0);
      start = math.min(start, end);

      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end,
              curve: Curves.elasticOut), // Curva consistente
        ),
      );
    });
  }

  // Reinicia animación (ej., al volver atrás)
  void _restartAnimation() {
    if (!mounted) return; // Comprobación extra
    if (_bubbleAnimations.length != subcategorias.length) {
      _initializeAnimations();
    }
    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Helper para navegación que incluye reinicio de animación
  void _navigateTo(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page))
        .then((_) => _restartAnimation()); // Reinicia animación al volver (pop)
  }

  @override
  Widget build(BuildContext context) {
    // Obtiene datos del tema
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        // Usa colores del tema
        title:
            Text(widget.tipoAlimento), // Muestra categoría principal en título
        actions: [
          // Usa iconos tematizados y helper de navegación consistente
          IconButton(
            icon: const Icon(Icons.history_outlined),
            tooltip: "Historial",
            onPressed: () => _navigateTo(const HistorialRecetas()),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: "Ajustes",
            onPressed: () => _navigateTo(const PaginaAjustes()),
          ),
        ],
      ),
      // Body ya no necesita el Container con gradiente
      body: Column(
        children: [
          // Texto de Cabecera - Tematizado y Animado
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
            child: Text(
              "Gastronomías de ${widget.tipoAlimento}",
              style: textTheme.headlineMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms, duration: 500.ms), // Fade in
          ),
          // Área de Layout de Burbujas
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calcula posiciones (consistente con Pantallaprincipal)
                final double boxWidth = constraints.maxWidth;
                final double boxHeight = constraints.maxHeight;
                final double centerX = boxWidth / 2;
                final double centerY = boxHeight / 2; // Ligeramente más arriba
                final double minSide = math.min(boxWidth, boxHeight);
                final double radius = minSide * 0.35; // Radio exterior
                final double outerBubbleSize =
                    minSide * 0.28; // Tamaño burbujas gastronomía
                final double centerBubbleSize =
                    minSide * 0.30; // Tamaño burbuja categoría central

                // --- DEBUG: Añade un contenedor con borde ---
                return Container(
                  width: constraints
                      .maxWidth, // Asegura que use todo el ancho dado
                  height: constraints
                      .maxHeight, // Asegura que use todo el alto dado

                  // --- FIN DEBUG ---
                  child: Stack(
                    // El Stack ahora está dentro del Container con borde
                    alignment: Alignment.center,
                    children: [
                      // Burbujas Exteriores (Gastronomías) - Usa la función corregida
                      ..._buildBurbujas(
                        centerX: centerX,
                        centerY: centerY,
                        radius: radius,
                        bubbleSize: outerBubbleSize,
                      ),

                      // Burbuja Central (Categoría Principal) - Estilizada y Animada
                      Container(
                        width: centerBubbleSize,
                        height: centerBubbleSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme
                              .secondaryContainer, // Usa color del tema
                          boxShadow: [
                            // Usa sombra del tema
                            BoxShadow(
                              color: colorScheme.shadow.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(2, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            widget.tipoAlimento,
                            style: textTheme.titleMedium?.copyWith(
                              // Usa estilo de texto apropiado
                              color: colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ).animate().scale(
                          delay: 100.ms,
                          duration: 600.ms,
                          curve: Curves.easeOutBack), // Anima escala
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- UPDATED _buildBurbujas METHOD ---
  List<Widget> _buildBurbujas({
    required double centerX,
    required double centerY,
    required double radius,
    required double bubbleSize, // Tamaño FINAL de la burbuja
  }) {
    final List<Widget> bubbles = [];
    final int n = subcategorias.length;

    // Asegúrate que la lista de animaciones coincide
    if (_bubbleAnimations.length != n) {
      _initializeAnimations();
    }
    if (_bubbleAnimations.isEmpty && n > 0) {
      print(
          "Warning: _bubbleAnimations is empty but subcategorias is not. Re-initializing.");
      _initializeAnimations();
      if (_bubbleAnimations.isEmpty) return [];
    } else if (n == 0) {
      return [];
    }

    for (int i = 0; i < n; i++) {
      final String subcat = subcategorias[i];
      final double angle = -math.pi / 2 + (2 * math.pi * i) / n;
      final String? imageUrl = subcategoriasImagenes[subcat];

      bubbles.add(
        AnimatedBuilder(
          animation: _bubbleAnimations[i],
          builder: (context, child) {
            if (i < _bubbleAnimations.length) {
              double value = _bubbleAnimations[i].value;
              final double currentRadius = radius * value;
              final double x = centerX + currentRadius * math.cos(angle);
              final double y = centerY + currentRadius * math.sin(angle);

              final double finalLeft = x - (bubbleSize / 2);
              final double finalTop = y - (bubbleSize / 2);

              if (value <= 0 || finalLeft.isNaN || finalTop.isNaN) {
                return const SizedBox.shrink();
              }

              return Positioned(
                left: finalLeft,
                top: finalTop,
                child: Opacity(
                  opacity: math.min(value * 1.5, 1.0),
                  child: Transform.scale(
                    scale: value,
                    child: child!, // Just pass the child directly
                  ),
                ),
              );
            } else {
              return const SizedBox.shrink();
            }
          },
          child: Burbujawidget(
            text: subcat,
            size: bubbleSize,
            imageUrl: imageUrl,
            fontSizeMultiplier: 0.09, // <-- ADJUST THIS VALUE (e.g., 0.10, 0.09)
            onTap: () {
              print(
                  "Navegando con Categoria: ${widget.tipoAlimento}, Gastronomia: $subcat");
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ListaRecetas(
                    mainCategory: widget.tipoAlimento,
                    subCategory: subcat,
                  ),
                ),
              ).then((_) => _restartAnimation());
            },
          ),
        ),
      );
    }
    return bubbles;
  }
  // --- END OF UPDATED _buildBurbujas METHOD ---
}
