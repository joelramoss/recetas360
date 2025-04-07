import 'package:flutter/material.dart';
import 'package:recetas360/components/Receta.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PasosRecetaScreen extends StatefulWidget {
  final Receta receta;
  
  const PasosRecetaScreen({Key? key, required this.receta}) : super(key: key);
  
  @override
  _PasosRecetaScreenState createState() => _PasosRecetaScreenState();
}

class _PasosRecetaScreenState extends State<PasosRecetaScreen> {
  int _currentStep = 0;
  bool _timerRunning = false;
  Timer? _timer;
  int _secondsRemaining = 0;
  late DateTime _endTime;
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Método para analizar el texto y encontrar instrucciones de tiempo
  int? _extractTimeInMinutes(String stepText) {
    final RegExp regExp = RegExp(r'durante (\d+) minutos', caseSensitive: false);
    final RegExp regExp2 = RegExp(r'(\d+) minutos', caseSensitive: false);
    
    final match = regExp.firstMatch(stepText) ?? regExp2.firstMatch(stepText);
    if (match != null) {
      return int.parse(match.group(1)!);
    }
    return null;
  }
  
  void _startTimer(int minutes) {
    setState(() {
      _secondsRemaining = minutes * 60;
      _timerRunning = true;
    });
    
    // Guardar la hora de finalización para mostrar el temporizador correctamente
    _endTime = DateTime.now().add(Duration(minutes: minutes));
    
    // Mantener el temporizador visual para cuando la app está en primer plano
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      
      // Si ya hemos pasado la hora de finalización
      if (now.isAfter(_endTime)) {
        setState(() {
          _secondsRemaining = 0;
          _timerRunning = false;
          _timer?.cancel();
          
          // Mostrar alerta cuando finalice el tiempo (reemplaza la notificación)
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('¡Tiempo completado para tu receta de ${widget.receta.nombre}!'),
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'OK',
                  onPressed: () {},
                ),
              ),
            );
          }
        });
      } else {
        // Calcular segundos restantes basados en la hora actual
        final remaining = _endTime.difference(now).inSeconds;
        setState(() {
          _secondsRemaining = remaining;
        });
      }
    });
  }
  
  String _formatTime(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _guardarRecetaCompletada() async {
    try {
      // Obtener fecha y hora actual
      final now = DateTime.now();
      
      // Obtener el usuario actual
      final User? currentUser = FirebaseAuth.instance.currentUser;
      final String userId = currentUser?.uid ?? 'usuario_anonimo';
      
      await FirebaseFirestore.instance.collection('recetas_completadas').add({
        'receta_id': widget.receta.id,
        'nombre': widget.receta.nombre,
        'urlImagen': widget.receta.urlImagen,
        'categoria': widget.receta.categoria,
        'gastronomia': widget.receta.gastronomia,
        'fecha_completado': now,
        'timestamp': FieldValue.serverTimestamp(),
        'usuario_id': userId, // Agregar el ID del usuario
      });
      
      // Opcional: Mostrar confirmación
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Receta añadida a tu historial!')),
        );
      }
    } catch (e) {
      print('Error al guardar receta completada: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar en el historial')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> pasos = widget.receta.pasos ?? [];
    
    // Si no hay pasos disponibles
    if (pasos.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.orangeAccent,
          title: const Text('Pasos de la Receta'),
        ),
        body: const Center(
          child: Text('No hay pasos disponibles para esta receta'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orangeAccent,
        title: const Text('Pasos de la Receta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              // Confirmar antes de salir si hay un temporizador activo
              if (_timerRunning) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirmar salida'),
                    content: const Text('El temporizador está en marcha. ¿Deseas salir?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          _timer?.cancel();
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: const Text('Salir'),
                      ),
                    ],
                  ),
                );
              } else {
                Navigator.pop(context);
              }
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
            // Encabezado
            Container(
              width: double.infinity,
              height: 50,
              child: Center(
                child: Text(
                  "Paso ${_currentStep + 1}/${pasos.length}",
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
                ),
              ),
            ),
            
            // Contenido principal
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Instrucción actual
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              pasos[_currentStep],
                              style: const TextStyle(
                                fontSize: 18,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                        
                        // Temporizador (si corresponde)
                        if (_extractTimeInMinutes(pasos[_currentStep]) != null && !_timerRunning)
                          Center(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.timer),
                              label: Text(
                                'Iniciar temporizador (${_extractTimeInMinutes(pasos[_currentStep])} minutos)',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orangeAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: () {
                                _startTimer(_extractTimeInMinutes(pasos[_currentStep])!);
                              },
                            ),
                          ),
                          
                        if (_timerRunning)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Column(
                              children: [
                                Text(
                                  _formatTime(_secondsRemaining),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: _secondsRemaining / 
                                      (_extractTimeInMinutes(pasos[_currentStep])! * 60),
                                  backgroundColor: Colors.grey.shade300,
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    Colors.orangeAccent,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _timerRunning = false;
                                      _timer?.cancel();
                                    });
                                  },
                                  child: const Text('Cancelar temporizador'),
                                ),
                              ],
                            ),
                          ),
                        
                        const SizedBox(height: 16),
                        
                        // Botones de navegación
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Botón anterior
                            ElevatedButton.icon(
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Anterior'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _currentStep > 0 
                                    ? Colors.orangeAccent 
                                    : Colors.grey,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: _currentStep > 0
                                  ? () {
                                      if (_timerRunning) {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('El temporizador está en marcha'),
                                            content: const Text('¿Deseas cambiar de paso?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Cancelar'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  _timer?.cancel();
                                                  setState(() {
                                                    _timerRunning = false;
                                                    _currentStep--;
                                                  });
                                                  Navigator.pop(context);
                                                },
                                                child: const Text('Continuar'),
                                              ),
                                            ],
                                          ),
                                        );
                                      } else {
                                        setState(() {
                                          _currentStep--;
                                        });
                                      }
                                    }
                                  : null,
                            ),
                            
                            // Botón siguiente o finalizar
                            ElevatedButton.icon(
                              icon: Icon(_currentStep < pasos.length - 1
                                  ? Icons.arrow_forward
                                  : Icons.check),
                              label: Text(
                                _currentStep < pasos.length - 1
                                    ? 'Siguiente'
                                    : 'Finalizar',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orangeAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: () {
                                if (_timerRunning) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('El temporizador está en marcha'),
                                      content: const Text('¿Deseas cambiar de paso?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Cancelar'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            _timer?.cancel();
                                            setState(() {
                                              _timerRunning = false;
                                              if (_currentStep < pasos.length - 1) {
                                                _currentStep++;
                                              } else {
                                                _guardarRecetaCompletada().then((_) {
                                                  Navigator.pop(context);
                                                });
                                              }
                                            });
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Continuar'),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  setState(() {
                                    if (_currentStep < pasos.length - 1) {
                                      _currentStep++;
                                    } else {
                                      _guardarRecetaCompletada().then((_) {
                                        Navigator.pop(context);
                                      });
                                    }
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}