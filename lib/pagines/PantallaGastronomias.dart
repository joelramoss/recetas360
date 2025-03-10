import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:recetas360/components/ListaRecetas.dart';
import 'package:recetas360/pagines/InterfazAjustes.dart';
import '../widgetsutilizados/burbujaestilo.dart';

class PantallaGastronomias extends StatefulWidget {
  final String tipoAlimento;
  const PantallaGastronomias({Key? key, required this.tipoAlimento}) : super(key: key);
  
  @override
  State<PantallaGastronomias> createState() => _PantallaGastronomiasState();
}

class _PantallaGastronomiasState extends State<PantallaGastronomias>
    with SingleTickerProviderStateMixin {
  // Lista de subcategorías
  final List<String> subcategorias = ["Mediterránea", "Asiática", "Americana", "Africana", "Oceánica"];
  
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
    final int n = subcategorias.length;
    _bubbleAnimations = List.generate(n, (i) {
      double start = i * 0.2;
      double end = start + 0.2;
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Interval(start, end, curve: Curves.easeOutCirc)),
      );
    });
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
            iconSize: 32.0,
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
              height: 50,
              child: Center(
                child: Text(
                  "Gastronomías de ${widget.tipoAlimento}",
                  style: const TextStyle(
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
                  textAlign: TextAlign.center,
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
                  final double radius = minSide * 0.37;
                  final double outerBubbleSize = minSide * 0.28;
                  final double centerBubbleSize = minSide * 0.20;
                  
                  return Stack(
                    children: [
                      ..._buildBurbujas(
                        centerX: centerX,
                        centerY: centerY,
                        radius: radius,
                        bubbleSize: outerBubbleSize,
                      ),
                      // Burbuja central con el nombre principal
                      Positioned(
                        left: centerX - centerBubbleSize,
                        top: centerY - centerBubbleSize,
                        child: Container(
                          width: centerBubbleSize * 2,
                          height: centerBubbleSize * 2,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.orangeAccent,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              widget.tipoAlimento,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 25
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
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
    final int n = subcategorias.length;
    for (int i = 0; i < n; i++) {
      final String subcat = subcategorias[i];
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
            text: subcat,
            size: bubbleSize,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ListaRecetas(
                    mainCategory: widget.tipoAlimento,
                    subCategory: subcat,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
    return bubbles;
  }
}
