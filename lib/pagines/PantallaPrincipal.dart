import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:recetas360/components/CarritoRestante.dart';
import 'package:recetas360/pagines/InterfazAjustes.dart';
import 'package:recetas360/pagines/PantallaGastronomias.dart';
import 'package:recetas360/pagines/HistorialRecetas.dart';
import 'package:recetas360/pagines/RecetasFavoritas.dart';
import 'package:recetas360/widgetsutilizados/burbujaestilo.dart';

import 'package:flutter_animate/flutter_animate.dart';

// Current User's Login: joelramoss
// Current Date and Time (UTC - YYYY-MM-DD HH:MM:SS formatted): 2025-04-24 15:13:49

class Pantallaprincipal extends StatefulWidget {
  const Pantallaprincipal({super.key});

  @override
  State<Pantallaprincipal> createState() => _PantallaBurbujasState();
}

class _PantallaBurbujasState extends State<Pantallaprincipal>
    with SingleTickerProviderStateMixin {
  final Map<String, String> tiposAlimento = {
    "Carne": "assets/images/carne.png",
    "Pescado": "assets/images/pescado.png",
    "Verduras": "assets/images/verdura.png",
    "Lácteos": "assets/images/lacteos.png",
    "Cereales": "assets/images/cereales.png",
  };
  final String imagenTodo = "assets/images/todo.png";

  late AnimationController _controller;
  late List<Animation<double>> _bubbleAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _initializeAnimations(); // Inicialización principal
    _controller.forward();
  }

  void _initializeAnimations() {
    final int n = tiposAlimento.length;
    if (n == 0) { // Manejo por si tiposAlimento estuviera vacío
      _bubbleAnimations = [];
      return;
    }
    final double intervalLength = 0.6 / n;
    const double startOffset = 0.1;

    _bubbleAnimations = List.generate(n, (i) {
      double start = startOffset + (i * intervalLength * 0.8);
      double end = start + intervalLength;
      end = math.min(end, 1.0);
      start = math.min(start, end);

      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.elasticOut),
        ),
      );
    });
  }

  void _restartAnimation() {
    // Esta comprobación es aceptable aquí ya que _restartAnimation no es un método de build.
    if (_bubbleAnimations.length != tiposAlimento.length) {
      _initializeAnimations();
    }
    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateTo(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page))
        .then((_) => _restartAnimation());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Recetas 360"),
        actions: [
          IconButton(
              icon: const Icon(Icons.favorite_border_outlined),
              tooltip: "Favoritos",
              onPressed: () => _navigateTo(const RecetasFavoritas())),
          IconButton(
              icon: const Icon(Icons.history_outlined),
              tooltip: "Historial",
              onPressed: () => _navigateTo(const HistorialRecetas())),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            iconSize: 25,
            tooltip: "Carrito",
            onPressed: () => _navigateTo(const CarritoFaltantes()),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            iconSize: 25,
            tooltip: "Ajustes",
            onPressed: () => _navigateTo(const PaginaAjustes()),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
            child: Text(
              "Explora tus categorías",
              style: textTheme.headlineMedium?.copyWith(
                  color: colorScheme.primary, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double boxWidth = constraints.maxWidth;
                final double boxHeight = constraints.maxHeight;
                final double centerX = boxWidth / 2;
                final double centerY = boxHeight / 2;
                final double minSide = math.min(boxWidth, boxHeight);
                final double radius = minSide * 0.35;
                final double outerBubbleSize = minSide * 0.29;
                final double centerBubbleSize = minSide * 0.33;

                return SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ..._buildBurbujas(
                        centerX: centerX,
                        centerY: centerY,
                        radius: radius,
                        bubbleSize: outerBubbleSize,
                      ),
                      Burbujawidget(
                        text: "Todo",
                        size: centerBubbleSize,
                        imageUrl: imagenTodo,
                        onTap: () => _navigateTo(const PantallaGastronomias(
                            tipoAlimento: "Todo")),
                      ).animate().scale(
                          delay: 500.ms,
                          duration: 800.ms,
                          curve: Curves.elasticOut),
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

  List<Widget> _buildBurbujas({
    required double centerX,
    required double centerY,
    required double radius,
    required double bubbleSize,
  }) {
    final List<Widget> bubbles = [];
    final entries = tiposAlimento.entries.toList();
    final int n = entries.length;

    // Se elimina la llamada a _initializeAnimations() de aquí.
    // Se confía en que initState y _restartAnimation manejan la inicialización.
    if (_bubbleAnimations.length != n) {
      // Esto no debería ocurrir si la lógica de estado es correcta.
      // Devolver una lista vacía para evitar errores de rango.
      print("Advertencia: Discrepancia en la longitud de _bubbleAnimations en _buildBurbujas. Se esperaba $n, se obtuvo ${_bubbleAnimations.length}.");
      return [];
    }

    for (int i = 0; i < n; i++) {
      final String tipo = entries[i].key;
      final String url = entries[i].value;
      final double angle = -math.pi / 2 + (2 * math.pi * i) / n;

      bubbles.add(
        AnimatedBuilder(
          animation: _bubbleAnimations[i],
          builder: (context, child) {
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
                  child: child,
                ),
              ),
            );
          },
          child: Burbujawidget(
            text: tipo,
            size: bubbleSize,
            imageUrl: url,
            onTap: () => _navigateTo(PantallaGastronomias(tipoAlimento: tipo)),
          ),
        ),
      );
    }
    return bubbles;
  }
}

