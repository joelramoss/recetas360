import 'package:flutter/material.dart';
import 'package:recetas360/components/Receta.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Import animate

// Current User's Login: joelramoss
// Current Date and Time (UTC - YYYY-MM-DD HH:MM:SS formatted): 2025-04-24 14:50:00

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
  DateTime? _endTime; // Make nullable

  // Store step duration to calculate progress correctly
  int _currentTimerDurationMinutes = 0;

  // Key for animating step text changes
  final GlobalKey _stepSwitcherKey = GlobalKey();


  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Extract time (remains the same)
  int? _extractTimeInMinutes(String stepText) {
    final RegExp regExp = RegExp(r'durante (\d+) minutos', caseSensitive: false);
    final RegExp regExp2 = RegExp(r'(\d+) minutos', caseSensitive: false);

    final match = regExp.firstMatch(stepText) ?? regExp2.firstMatch(stepText);
    if (match != null) {
      final minutes = int.tryParse(match.group(1)!);
      return minutes != null && minutes > 0 ? minutes : null; // Ensure positive time
    }
    return null;
  }

  // Start Timer Logic
  void _startTimer(int minutes) {
    if (minutes <= 0) return; // Don't start timer for 0 or negative minutes

    _currentTimerDurationMinutes = minutes; // Store duration
    final now = DateTime.now();
    _endTime = now.add(Duration(minutes: minutes));
    _secondsRemaining = minutes * 60;

    setState(() {
      _timerRunning = true;
    });


    _timer?.cancel(); // Cancel any existing timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_endTime == null) { // Safety check
         timer.cancel();
         return;
      }

      final currentTime = DateTime.now();
      if (currentTime.isAfter(_endTime!)) {
         // Timer finished
        setState(() {
          _secondsRemaining = 0;
          _timerRunning = false;
          _timer?.cancel();
        });

        // Show completion SnackBar
        if (mounted) {
           final colorScheme = Theme.of(context).colorScheme;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('¡Tiempo completado para el paso!'),
              // backgroundColor: colorScheme.primaryContainer, // Use theme indication
              // duration: const Duration(seconds: 5), // Default duration is usually fine
              action: SnackBarAction(
                label: 'OK',
                textColor: colorScheme.inversePrimary, // Ensure contrast
                onPressed: () {},
              ),
            ),
          );
        }
      } else {
        // Update remaining time
        if (mounted) {
           setState(() {
             _secondsRemaining = _endTime!.difference(currentTime).inSeconds;
           });
        } else {
           // If widget is disposed while timer is running, cancel timer
           timer.cancel();
        }
      }
    });
  }

  // Format Time (remains the same)
  String _formatTime(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Cancel Timer Logic
  void _cancelTimer() {
    setState(() {
      _timerRunning = false;
      _timer?.cancel();
      _secondsRemaining = 0; // Reset seconds
      _endTime = null;
    });
  }

  // Save Completed Recipe (remains mostly the same, add theme to SnackBar)
  Future<void> _guardarRecetaCompletada() async {
     final colorScheme = Theme.of(context).colorScheme;
    try {
      final now = DateTime.now();
      final User? currentUser = FirebaseAuth.instance.currentUser;
      final String userId = currentUser?.uid ?? 'usuario_anonimo'; // Use a placeholder or handle error

      await FirebaseFirestore.instance.collection('recetas_completadas').add({
        'receta_id': widget.receta.id,
        'nombre': widget.receta.nombre,
        'urlImagen': widget.receta.urlImagen, // Consider if needed in history
        'categoria': widget.receta.categoria,
        'gastronomia': widget.receta.gastronomia,
        // 'fecha_completado': now, // Redundant if using timestamp
        'timestamp': FieldValue.serverTimestamp(), // Use server timestamp
        'usuario_id': userId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Receta añadida a tu historial!')),
        );
      }
    } catch (e) {
      print('Error al guardar receta completada: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo guardar en el historial.', style: TextStyle(color: colorScheme.onError)),
             backgroundColor: colorScheme.error,
            ),
        );
      }
    }
  }

   // --- Navigation Logic ---
  void _goToStep(int stepIndex) {
     if (stepIndex >= 0 && stepIndex < (widget.receta.pasos.length)) {
        setState(() {
           _currentStep = stepIndex;
           // Cancel timer when manually changing steps
           if (_timerRunning) {
              _cancelTimer();
           }
        });
     } else if (stepIndex >= widget.receta.pasos.length) {
        // Reached the end, finalize
         _guardarRecetaCompletada().then((_) {
            if (mounted) {
               Navigator.pop(context); // Go back after saving
            }
         });
     }
  }

  // --- Handle Back/Next Press ---
  void _handleNavigation(int nextStepIndex) {
     if (_timerRunning) {
        // If timer is running, ask for confirmation
        _showTimerConfirmationDialog().then((confirmed) {
           if (confirmed == true) {
              _cancelTimer(); // Cancel timer first
              _goToStep(nextStepIndex); // Then go to the step
           }
           // If not confirmed, do nothing
        });
     } else {
        // If timer not running, just go to the step
        _goToStep(nextStepIndex);
     }
  }

   // --- Confirmation Dialog ---
   Future<bool?> _showTimerConfirmationDialog() {
      final colorScheme = Theme.of(context).colorScheme;
      return showDialog<bool>(
         context: context,
         builder: (context) => AlertDialog(
            // Themed AlertDialog
            title: const Text('El temporizador está activo'),
            content: const Text('Si cambias de paso se cancelará el temporizador actual. ¿Continuar?'),
            actions: [
               TextButton(
                  onPressed: () => Navigator.pop(context, false), // Not confirmed
                  child: const Text('Cancelar'),
               ),
               TextButton(
                  onPressed: () => Navigator.pop(context, true), // Confirmed
                   // Optional: Style confirmation button differently
                  // style: TextButton.styleFrom(foregroundColor: colorScheme.error),
                  child: const Text('Continuar'),
               ),
            ],
         ),
      );
   }

   // --- Exit Confirmation Dialog ---
   Future<bool?> _showExitConfirmationDialog() {
      return showDialog<bool>(
         context: context,
         builder: (context) => AlertDialog(
            title: const Text('¿Salir de la receta?'),
            content: Text(_timerRunning
                ? 'El temporizador está activo y se cancelará si sales.'
                : '¿Estás seguro de que quieres salir?'),
            actions: [
               TextButton(
                  onPressed: () => Navigator.pop(context, false), // Don't exit
                  child: const Text('Cancelar'),
               ),
               TextButton(
                  onPressed: () => Navigator.pop(context, true), // Confirm exit
                  child: const Text('Salir'),
               ),
            ],
         ),
      );
   }

  @override
  Widget build(BuildContext context) {
    final List<String> pasos = widget.receta.pasos;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Handle case where there are no steps
    if (pasos.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.receta.nombre)), // Show recipe name
        body: Center(
          child: Text(
             'No hay pasos disponibles para esta receta.',
             style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    final int totalSteps = pasos.length;
    final String currentStepText = pasos[_currentStep];
    final int? minutesForTimer = _extractTimeInMinutes(currentStepText);
    final bool isLastStep = _currentStep == totalSteps - 1;

    // Use WillPopScope to intercept back button press if timer is running
    return WillPopScope(
       onWillPop: () async {
         if (_timerRunning) {
            final confirmExit = await _showExitConfirmationDialog();
            if (confirmExit == true) {
               _cancelTimer(); // Cancel timer before popping
               return true; // Allow pop
            }
            return false; // Prevent pop
         }
         return true; // Allow pop if timer isn't running
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.receta.nombre), // Show recipe name in AppBar
          // Close button handled by WillPopScope and Navigator's back button
        ),
        // Removed Container with gradient
        body: Column(
          children: [
            // --- Step Counter Header ---
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              child: Text(
                "Paso ${_currentStep + 1} / $totalSteps",
                style: textTheme.titleMedium?.copyWith(
                   color: colorScheme.primary,
                   fontWeight: FontWeight.bold
                ),
              ).animate().fadeIn(), // Simple fade for header
            ),

            // --- Main Content Card ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                child: Card(
                  elevation: 2, // M3 elevation
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // M3 shape
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch children
                      children: [
                        // --- Step Instruction ---
                        Expanded(
                          child: SingleChildScrollView(
                             // Use AnimatedSwitcher for step text transitions
                             child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (Widget child, Animation<double> animation) {
                                   // Slide transition
                                   return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                         position: Tween<Offset>(
                                            begin: const Offset(0.1, 0.0), // Slide in from right
                                            end: Offset.zero,
                                         ).animate(animation),
                                         child: child,
                                      ),
                                   );
                                },
                                child: Text(
                                   // Use Key to trigger animation on change
                                   currentStepText,
                                   key: ValueKey<int>(_currentStep),
                                   style: textTheme.bodyLarge?.copyWith(height: 1.5), // Use themed text style
                                ),
                             ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // --- Timer Section ---
                        // Show button if timer is applicable and not running
                        if (minutesForTimer != null && !_timerRunning)
                          Center(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.timer_outlined),
                              label: Text('Iniciar $minutesForTimer min'),
                              style: ElevatedButton.styleFrom(
                                // backgroundColor: colorScheme.secondaryContainer, // Use theme colors
                                // foregroundColor: colorScheme.onSecondaryContainer,
                              ),
                              onPressed: () => _startTimer(minutesForTimer),
                            ),
                          ).animate().fadeIn(),

                        // Show timer progress if running
                        if (_timerRunning)
                          Column(
                            children: [
                              Text(
                                _formatTime(_secondsRemaining),
                                style: textTheme.headlineSmall?.copyWith(
                                   color: colorScheme.primary,
                                   fontWeight: FontWeight.bold
                                ),
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                // Calculate progress based on initial duration
                                value: (_currentTimerDurationMinutes * 60 > 0)
                                      ? _secondsRemaining / (_currentTimerDurationMinutes * 60)
                                      : 0.0,
                                backgroundColor: colorScheme.surfaceContainerHighest, // Use theme background
                                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary), // Use theme primary
                                minHeight: 6, // Slightly thicker bar
                                borderRadius: BorderRadius.circular(3),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _cancelTimer,
                                child: const Text('Cancelar temporizador'),
                              ),
                            ],
                          ).animate().fadeIn(), // Animate timer appearance

                        const SizedBox(height: 16),

                        // --- Navigation Buttons ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Previous Button
                            ElevatedButton.icon(
                              icon: const Icon(Icons.arrow_back_ios_new_rounded),
                              label: const Text('Anterior'),
                              style: ElevatedButton.styleFrom(
                                 // Disable visually if it's the first step
                                 backgroundColor: _currentStep > 0 ? null : colorScheme.onSurface.withOpacity(0.12),
                                 foregroundColor: _currentStep > 0 ? null : colorScheme.onSurface.withOpacity(0.38),
                              ),
                              // Disable onPressed if it's the first step
                              onPressed: _currentStep > 0 ? () => _handleNavigation(_currentStep - 1) : null,
                            ),

                            // Next / Finish Button
                            ElevatedButton.icon(
                              icon: Icon(isLastStep ? Icons.check_circle_outline_rounded : Icons.arrow_forward_ios_rounded),
                              label: Text(isLastStep ? 'Finalizar' : 'Siguiente'),
                              style: ElevatedButton.styleFrom(
                                 // Optional: Style finish button differently
                                 // backgroundColor: isLastStep ? colorScheme.primary : null,
                                 // foregroundColor: isLastStep ? colorScheme.onPrimary : null,
                              ),
                              onPressed: () => _handleNavigation(_currentStep + 1),
                            ),
                          ],
                        ).animate().fadeIn(delay: 100.ms), // Animate buttons
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