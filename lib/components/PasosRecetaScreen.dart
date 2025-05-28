import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recetas360/components/Receta.dart';
import 'package:just_audio/just_audio.dart';


class PasosRecetaScreen extends StatefulWidget {
  final Receta receta;

  const PasosRecetaScreen({super.key, required this.receta});

  @override
  _PasosRecetaScreenState createState() => _PasosRecetaScreenState();
}

class _PasosRecetaScreenState extends State<PasosRecetaScreen> {
  late final PageController _pageController;
  late final Map<int, int> _stepDurationMap;

  Timer? _timer; // Timer para la cuenta regresiva del paso
  bool _timerRunning = false;
  int _secondsRemaining = 0;
  int _initialDurationSeconds = 0;

  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _notificationSoundTimer; // Timer para auto-detener el sonido de notificación

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _stepDurationMap = _parseTimersFromSteps(widget.receta.pasos);
    _pageController.addListener(_onPageChanged);
    _onPageChanged(); // Inicializa tiempo del primer paso
  }

  @override
  void dispose() {
    _timer?.cancel();
    _notificationSoundTimer?.cancel(); // Asegúrate de cancelar este timer también
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onPageChanged() {
    _stopNotificationSound(); // Detener sonido si cambia la página
    final page = _pageController.hasClients ? _pageController.page?.round() ?? 0 : 0;
    if (_timerRunning) _cancelTimer();
    final seconds = _stepDurationMap[page] ?? 0;
    setState(() {
      _initialDurationSeconds = seconds;
      _secondsRemaining = seconds;
    });
  }

  Map<int, int> _parseTimersFromSteps(List<String> steps) {
    final Map<int, int> timers = {};
    final hoursRegex = RegExp(r'(\d+)\s*(h|horas?|hrs?)', caseSensitive: false);
    final minSecRegex = RegExp(
      r'(\d+(?:[–\-]\d+)?)\s*(horas?|h|mins?|min|segundos?|secs?|s)',
      caseSensitive: false,
    );
    for (var i = 0; i < steps.length; i++) {
      int maxSec = 0;
      for (final m in hoursRegex.allMatches(steps[i])) {
        final h = int.tryParse(m.group(1)!) ?? 0;
        maxSec = max(maxSec, h * 3600);
      }
      for (final m in minSecRegex.allMatches(steps[i])) {
        String numStr = m.group(1)!;
        int value;
        if (numStr.contains('–') || numStr.contains('-')) {
          final parts = numStr.split(RegExp(r'[–\-]')).map((s) => int.tryParse(s) ?? 0);
          value = parts.reduce((a, b) => max(a, b));
        } else {
          value = int.tryParse(numStr) ?? 0;
        }
        final unit = m.group(2)!.toLowerCase();
        final seconds = unit.startsWith('h')
            ? value * 3600
            : (unit.startsWith('s') ? value : value * 60);
        maxSec = max(maxSec, seconds);
      }
      if (maxSec > 0) timers[i] = maxSec;
    }
    return timers;
  }

  void _startTimer(int seconds) {
    if (seconds <= 0 || _timerRunning) return;
    _initialDurationSeconds = seconds;
    final endTime = DateTime.now().add(Duration(seconds: seconds));
    setState(() {
      _timerRunning = true;
      _secondsRemaining = seconds;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      if (now.isAfter(endTime)) {
        timer.cancel();
        setState(() {
          _timerRunning = false;
          _secondsRemaining = 0;
        });
        _playNotificationSound(); // Reproducir sonido al finalizar
        if (mounted) {
          final colorScheme = Theme.of(context).colorScheme;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('¡Tiempo completado para el paso!'),
              action: SnackBarAction(
                label: 'Siguiente',
                onPressed: _goToNext,
                textColor: colorScheme.inversePrimary,
              ),
            ),
          );
        }
      } else {
        setState(() {
          _secondsRemaining = endTime.difference(now).inSeconds;
        });
      }
    });
  }

  /// Reproduce el sonido de notificación usando just_audio
  Future<void> _playNotificationSound() async {
    try {
      await _audioPlayer.setAsset('assets/sounds/notification.mp3');
      await _audioPlayer.play();
      
      _notificationSoundTimer?.cancel(); // Cancela cualquier timer anterior
      _notificationSoundTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) { // Buena práctica verificar si el widget sigue montado
          _audioPlayer.stop();
        }
      });
    } catch (e) {
      debugPrint('Error al reproducir sonido de notificación: $e');
    }
  }

  void _stopNotificationSound() {
    _audioPlayer.stop();
    _notificationSoundTimer?.cancel();
  }

  void _cancelTimer() {
    _timer?.cancel();
    setState(() {
      _timerRunning = false;
      _secondsRemaining = 0;
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _goToPrevious() {
    _stopNotificationSound(); // Detener sonido si va al paso anterior
    final prev = (_pageController.page?.round() ?? 0) - 1;
    if (prev >= 0) {
      _pageController.animateToPage(
        prev,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNext() {
    _stopNotificationSound(); // Detener el sonido al ir al siguiente paso
    final next = (_pageController.page?.round() ?? 0) + 1;
    if (next < widget.receta.pasos.length) {
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Si es el último paso, llama a guardar pero también detiene el sonido
      _guardarRecetaCompletada().then((_) {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    }
  }

  Future<void> _guardarRecetaCompletada() async {
    _stopNotificationSound(); // Detener el sonido al finalizar la receta
    final colorScheme = Theme.of(context).colorScheme;
    try {
      final user = FirebaseAuth.instance.currentUser;
      final id = user?.uid ?? 'usuario_anonimo';
      await FirebaseFirestore.instance.collection('recetas_completadas').add({
        'receta_id': widget.receta.id,
        'nombre': widget.receta.nombre,
        'categoria': widget.receta.categoria,
        'gastronomia': widget.receta.gastronomia,
        'timestamp': FieldValue.serverTimestamp(),
        'usuario_id': id,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Receta añadida a tu historial!')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se pudo guardar en el historial.',
              style: TextStyle(color: colorScheme.onError),
            ),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pasos = widget.receta.pasos;
    if (pasos.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.receta.nombre)),
        body: Center(child: Text('No hay pasos disponibles.')),
      );
    }
    final pageIndex = _pageController.hasClients ? _pageController.page?.round() ?? 0 : 0;
    final total = pasos.length;
    final isLast = pageIndex == total - 1;
    final hasTimer = _stepDurationMap.containsKey(pageIndex);

    return WillPopScope(
      onWillPop: () async {
        if (_timerRunning) {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Salir'),
              content: const Text('El temporizador está activo y se cancelará.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Salir'),
                ),
              ],
            ),
          );
          if (confirm == true) _cancelTimer();
          return confirm == true;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.receta.nombre)),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Paso ${pageIndex + 1} / $total',
                style: Theme.of(context).textTheme.titleMedium,
              ).animate().fadeIn(),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: total,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: Text(
                                pasos[i],
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          ),
                          if (hasTimer && i == pageIndex && !_timerRunning)
                            Center(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.timer_outlined),
                                label: Text('Iniciar ${(_stepDurationMap[i]! ~/ 60)} min'),
                                onPressed: () => _startTimer(_stepDurationMap[i]!),
                              ),
                            ),
                          if (_timerRunning && i == pageIndex)
                            SizedBox(
                              height: 180, // Aumentado de 150 a 180
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox( // Envuelve el CircularProgressIndicator para controlar su tamaño
                                    width: 120, // Define el ancho del indicador
                                    height: 120, // Define el alto del indicador
                                    child: CircularProgressIndicator(
                                      value: _initialDurationSeconds > 0
                                          ? _secondsRemaining / _initialDurationSeconds
                                          : 0,
                                      strokeWidth: 10, // Aumentado de 8 a 10 para mejor proporción
                                      backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                                    ),
                                  ),
                                  Text(
                                    _formatTime(_secondsRemaining),
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith( // Cambiado a headlineMedium
                                      fontWeight: FontWeight.bold, // Opcional: para hacerlo más prominente
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.arrow_back_ios),
                    label: const Text('Anterior'),
                    onPressed: pageIndex > 0 ? _goToPrevious : null,
                  ),
                  ElevatedButton.icon(
                    icon: Icon(isLast ? Icons.check_circle : Icons.arrow_forward_ios),
                    label: Text(isLast ? 'Finalizar' : 'Siguiente'),
                    onPressed: _goToNext, // Modificado para llamar siempre a _goToNext
                                         // _goToNext manejará la lógica de si es el último paso o no.
                  ),
                ],
              ).animate().fadeIn(),
            ),
          ],
        ),
      ),
    );
  }
}
