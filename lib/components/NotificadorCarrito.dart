// notificador_carrito.dart
import 'dart:async';
import 'package:flutter/material.dart';

class NotificadorCarrito extends StatefulWidget {
  final Duration intervalo; // tiempo entre notificaciones

  const NotificadorCarrito({super.key, this.intervalo = const Duration(minutes: 30)});

  @override
  State<NotificadorCarrito> createState() => _NotificadorCarritoState();
}

class _NotificadorCarritoState extends State<NotificadorCarrito> {
  Timer? _timer;
  Duration _intervaloActual = const Duration(minutes: 30);

  @override
  void initState() {
    super.initState();
    _iniciarTemporizador(_intervaloActual);
  }

  void _iniciarTemporizador(Duration intervalo) {
    _timer?.cancel();
    _timer = Timer.periodic(intervalo, (_) => _enviarNotificacion());
  }

  void _enviarNotificacion() {
    // Aquí tu lógica para enviar la notificación
    print("Notificación enviada");
  }

  Future<void> _mostrarDialogoIntervalo() async {
    int minutosSeleccionados = _intervaloActual.inMinutes;
    final resultado = await showDialog<int>(
      context: context,
      builder: (context) {
        int tempMinutos = minutosSeleccionados;
        return AlertDialog(
          title: const Text('Selecciona el intervalo (minutos)'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    min: 1,
                    max: 120,
                    divisions: 119,
                    value: tempMinutos.toDouble(),
                    label: '$tempMinutos',
                    onChanged: (value) {
                      setState(() {
                        tempMinutos = value.toInt();
                      });
                    },
                  ),
                  Text('$tempMinutos minutos'),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, tempMinutos),
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );

    if (resultado != null && resultado > 0) {
      setState(() {
        _intervaloActual = Duration(minutes: resultado);
        _iniciarTemporizador(_intervaloActual);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _mostrarDialogoIntervalo,
          child: const Text('Enviar Información'),
        ),
        Text('Intervalo actual: ${_intervaloActual.inMinutes} minutos'),
      ],
    );
  }
}

