import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:recetas360/pagines/InterfazAjustes.dart';
import 'package:recetas360/pagines/PantallaGastronomias.dart';
import '../widgetsutilizados/burbujaestilo.dart';

class Pantallaprincipal extends StatefulWidget {
  const Pantallaprincipal({Key? key}) : super(key: key);

  @override
  State<Pantallaprincipal> createState() => _PantallaBurbujasState();
}

class _PantallaBurbujasState extends State<Pantallaprincipal>
    with SingleTickerProviderStateMixin {
  // Mapa de categorías: nombre y URL de imagen
  final Map<String, String> tiposAlimento = {
    "Carne": "https://loremflickr.com/100/100/meat",
    "Pescado": "https://loremflickr.com/100/100/fish",
    "Verduras": "https://loremflickr.com/100/100/vegetables",
    "Lácteos": "https://loremflickr.com/100/100/dairy",
    "Cereales": "https://loremflickr.com/100/100/cereals",
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
    _bubbleAnimations = List.generate(n, (i) {
      double start = i * 0.2;
      double end = start + 0.2;
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
        backgroundColor: Colors.orangeAccent,
        actions: [
          IconButton(
            iconSize: 46,
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PaginaAjustes(),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        // Fondo degradado para toda la pantalla
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
            // Encabezado con texto centrado (estilo uniforme)
            Container(
              width: double.infinity,
              height: 50, // Altura del encabezado
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
            // Espacio flexible para las burbujas animadas
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double boxWidth = constraints.maxWidth;
                  final double boxHeight = constraints.maxHeight;
                  final double centerX = boxWidth / 2;
                  final double centerY = boxHeight / 2;
                  final double minSide = math.min(boxWidth, boxHeight);

                  // Radio para posicionar las burbujas alrededor de la central
                  final double radius = minSide * 0.30;
                  // Tamaño de las burbujas exteriores
                  final double outerBubbleSize = minSide * 0.28;
                  // Tamaño de la burbuja central
                  final double centerBubbleSize = minSide * 0.25;

                  return Stack(
                    children: [
                      // Burbujas animadas alrededor
                      ..._buildBurbujas(
                        centerX: centerX,
                        centerY: centerY,
                        radius: radius,
                        bubbleSize: outerBubbleSize,
                      ),
                      // Burbuja central
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
      // Distribuir las burbujas en un círculo alrededor de la central
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
            imageUrl: url,
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
