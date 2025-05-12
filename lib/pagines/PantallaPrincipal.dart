import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:recetas360/components/CarritoRestante.dart';
import 'package:recetas360/pagines/InterfazAjustes.dart';
import 'package:recetas360/pagines/PantallaGastronomias.dart';
import 'package:recetas360/pagines/HistorialRecetas.dart';
import 'package:recetas360/pagines/RecetasFavoritas.dart';
import '../widgetsutilizados/burbujaestilo.dart';// Asegúrate de importar esta pantalla

class Pantallaprincipal extends StatefulWidget {
  const Pantallaprincipal({Key? key}) : super(key: key);

  @override
  State<Pantallaprincipal> createState() => _PantallaBurbujasState();
}

class _PantallaBurbujasState extends State<Pantallaprincipal>
    with SingleTickerProviderStateMixin {
  // Mapa de categorías: nombre y URL de imagen
  final Map<String, String> tiposAlimento = {
    "Carne": "https://firebasestorage.googleapis.com/v0/b/...carne.jpg",
    "Pescado": "https://firebasestorage.googleapis.com/v0/b/...pescado.jpg",
    "Verduras": "https://firebasestorage.googleapis.com/v0/b/...verduras.jpg",
    "Lácteos": "https://firebasestorage.googleapis.com/v0/b/...lacteos.jpg",
    "Cereales": "https://firebasestorage.googleapis.com/v0/b/...cereales.jpg",
  };

  late AnimationController _controller;
  late List<Animation<double>> _bubbleAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _initializeAnimations();
    _controller.forward();
  }

  void _initializeAnimations() {
    final int n = tiposAlimento.length;
    final double intervalLength = 1.0 / n;

    _bubbleAnimations = List.generate(n, (i) {
      double start = i * intervalLength;
      double end = start + intervalLength;
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOutCirc),
        ),
      );
    });
  }

  void _restartAnimation() {
    _controller.reset();
    _initializeAnimations();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explora tus recetas'), // Título personalizado
        backgroundColor: Colors.orangeAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.white),
            iconSize: 32,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RecetasFavoritas(),
                ),
              ).then((_) {
                _restartAnimation();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            iconSize: 32,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HistorialRecetas(),
                ),
              ).then((_) {
                _restartAnimation();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            iconSize: 32,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CarritoFaltantes()),
              ).then((_) {
                _restartAnimation();
              });
            },
          ),
          IconButton(
            iconSize: 32,
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PaginaAjustes(),
                ),
              ).then((_) {
                _restartAnimation();
              });
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.orangeAccent,
              Colors.pink.shade100,
            ],
          ),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 50,
              child: const Center(
                child: Text(
                  "Explora tus categorías",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 4,
                        color: Colors.black45,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double boxWidth = constraints.maxWidth;
                  final double boxHeight = constraints.maxHeight;
                  final double centerX = boxWidth / 2;
                  final double centerY = boxHeight / 2;
                  final double minSide = math.min(boxWidth, boxHeight);

                  final double radius = minSide * 0.30;
                  final double outerBubbleSize = minSide * 0.28;
                  final double centerBubbleSize = minSide * 0.25;

                  return Stack(
                    children: [
                      ..._buildBurbujas(
                        centerX: centerX,
                        centerY: centerY,
                        radius: radius,
                        bubbleSize: outerBubbleSize,
                      ),
                      Positioned(
                        left: centerX - (centerBubbleSize / 2),
                        top: centerY - (centerBubbleSize / 2),
                        child: Burbujawidget(
                          text: "Comida",
                          size: centerBubbleSize,
                          onTap: () {},
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
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

    for (int i = 0; i < n; i++) {
      final String tipo = entries[i].key;
      final String url = entries[i].value;
      final double angle = -math.pi / 2 + (2 * math.pi * i) / n;

      bubbles.add(
        AnimatedBuilder(
          animation: _bubbleAnimations[i],
          builder: (context, child) {
            double value = _bubbleAnimations[i].value;
            final double x = centerX + radius * value * math.cos(angle);
            final double y = centerY + radius * value * math.sin(angle);

            return Positioned(
              left: x - (bubbleSize / 2),
              top: y - (bubbleSize / 2),
              child: Opacity(
                opacity: value,
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PantallaGastronomias(tipoAlimento: tipo),
                ),
              ).then((_) {
                _restartAnimation();
              });
            },
          ),
        ),
      );
    }
    return bubbles;
  }
}

