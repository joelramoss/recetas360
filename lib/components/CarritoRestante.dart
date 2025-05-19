import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recetas360/serveis/UsuarioUtil.dart';
import 'package:recetas360/components/Receta.dart';
import 'package:recetas360/components/DetalleReceta.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:android_intent_plus/android_intent.dart';

class CarritoFaltantes extends StatefulWidget {
  const CarritoFaltantes({Key? key}) : super(key: key);

  @override
  _CarritoFaltantesState createState() => _CarritoFaltantesState();
}

class _CarritoFaltantesState extends State<CarritoFaltantes> {
  final UsuarioUtil _usuarioUtil = UsuarioUtil();
  Map<String, Map<String, bool>> _ingredientesFaltantesPorReceta = {};
  final FlutterLocalNotificationsPlugin _notificacionesPlugin = FlutterLocalNotificationsPlugin();

  Stream<QuerySnapshot> _cargarRecetasFaltantes() {
    String? userId = _usuarioUtil.getUidUsuarioActual();
    if (userId == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .collection('recetas_faltantes')
        .snapshots();
  }

  Future<void> _actualizarIngrediente(String recetaId, String ingrediente, bool nuevoEstado) async {
    String? userId = _usuarioUtil.getUidUsuarioActual();
    if (userId == null) return;
    
    // Verificar si este es el último ingrediente faltante
    final ingredientesFaltantes = _ingredientesFaltantesPorReceta[recetaId] ?? {};
    ingredientesFaltantes[ingrediente] = nuevoEstado;
    
    final docRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .collection('recetas_faltantes')
        .doc(recetaId);
        
    try {
      if (nuevoEstado) {
        // Si el ingrediente ahora es faltante, lo actualizamos/agregamos
        await docRef.set({
          'ingredientes': {ingrediente: true},
          'actualizadoEn': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        // Si el ingrediente ya no es faltante, lo eliminamos del documento
        await docRef.update({
          'ingredientes.$ingrediente': FieldValue.delete(),
        });
        
        // Verificamos si quedan ingredientes faltantes
        final sigueHabiendoFaltantes = ingredientesFaltantes.values.any((faltante) => faltante);
        
        if (!sigueHabiendoFaltantes) {
          // Si no quedan ingredientes faltantes, eliminamos el documento completo
          await docRef.delete();
          setState(() {
            _ingredientesFaltantesPorReceta.remove(recetaId);
          });
        }
      }
    } catch (e) {
      print("Error al actualizar el ingrediente: $e");
      // Aquí podrías mostrar un SnackBar con el error
    }
  }

  @override
  void initState() {
    super.initState();
    _inicializarNotificaciones();
  }

  Future<void> _inicializarNotificaciones() async {
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidInit);
    await _notificacionesPlugin.initialize(initSettings);
  }


  Future<void> _programarNotificacionPersonalizada(int minutos, List<String> ingredientes) async {
    tz.initializeTimeZones();
    await _notificacionesPlugin.zonedSchedule(
      0,
      '¡Recuerda comprar!',
      'Te faltan: ${ingredientes.join(", ")}',
      tz.TZDateTime.now(tz.local).add(Duration(minutes: minutos)),
      const NotificationDetails(
        android: AndroidNotificationDetails('carrito_channel', 'Carrito', importance: Importance.max),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _mostrarDialogoIntervalo(List<String> ingredientes) async {
  int minutos = 5;
  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('¿Cada cuántos minutos quieres recibir recordatorios?'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  min: 1,
                  max: 60,
                  divisions: 59,
                  value: minutos.toDouble(),
                  label: '$minutos min',
                  onChanged: (value) {
                    setState(() {
                      minutos = value.toInt();
                    });
                  },
                ),
                Text('$minutos minutos'),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _programarNotificacionPersonalizada(minutos, ingredientes);
            },
            child: const Text('Aceptar'),
          ),
        ],
      );
    },
  );
}

  Future<void> solicitarPermisoExactAlarms() async {
  final intent = AndroidIntent(
    action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
  );
  await intent.launch();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orangeAccent,
        title: const Text('Carrito de compra'),
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
                  "Ingredientes Faltantes en tus Recetas",
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
              child: StreamBuilder<QuerySnapshot>(
                stream: _cargarRecetasFaltantes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No hay recetas con ingredientes faltantes",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    );
                  }

                  final recetasConFaltantes = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final ingredientes = Map<String, bool>.from(data['ingredientes'] ?? {});
                    _ingredientesFaltantesPorReceta[doc.id] = ingredientes;
                    return ingredientes.values.any((faltante) => faltante);
                  }).toList();

                  if (recetasConFaltantes.isEmpty) {
                    return const Center(
                      child: Text(
                        "¡No te falta nada en tus recetas!",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    );
                  }

                  final List<String> ingredientesTotales = [];
                  for (final doc in recetasConFaltantes) {
                    final data = doc.data() as Map<String, dynamic>;
                    final ingredientes = Map<String, bool>.from(data['ingredientes'] ?? {});
                    ingredientesTotales.addAll(
                      ingredientes.entries
                        .where((entry) => entry.value)
                        .map((entry) => entry.key)
                        .toList()
                    );
                  }
                  // Elimina duplicados
                  final ingredientesUnicos = ingredientesTotales.toSet().toList();

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: recetasConFaltantes.length,
                          itemBuilder: (context, index) {
                            final doc = recetasConFaltantes[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final ingredientes = _ingredientesFaltantesPorReceta[doc.id] ?? {};
                            final faltantes = ingredientes.entries
                                .where((entry) => entry.value)
                                .map((entry) => entry.key)
                                .toList();

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                              child: ExpansionTile(
                                title: Text(
                                  data['recetaNombre'] ?? 'Receta sin nombre',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                children: faltantes.map((ingrediente) {
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: ingredientes[ingrediente] == true
                                          ? Colors.redAccent
                                          : Colors.greenAccent,
                                      child: Icon(
                                        ingredientes[ingrediente] == true
                                            ? Icons.local_grocery_store
                                            : Icons.check,
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text(ingrediente),
                                    onTap: () {
                                      // Guardar el estado actual
                                      final estadoActual = ingredientes[ingrediente] ?? true;
                                      // Actualizar el estado local
                                      setState(() {
                                        ingredientes[ingrediente] = !estadoActual;
                                      });
                                      // Actualizar en Firestore (usando el valor opuesto al actual)
                                      _actualizarIngrediente(doc.id, ingrediente, !estadoActual);
                                    },
                                    onLongPress: () {
                                      FirebaseFirestore.instance
                                          .collection('recetas')
                                          .doc(doc.id)
                                          .get()
                                          .then((recetaDoc) {
                                        if (recetaDoc.exists) {
                                          final recetaData = recetaDoc.data()!;
                                          recetaData['id'] = recetaDoc.id;

                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => DetalleReceta(
                                                receta: Receta.fromFirestore(recetaData, recetaDoc.id),
                                              ),
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Esta receta ya no está disponible'),
                                            ),
                                          );
                                        }
                                      }).catchError((error) {
                                        print("Error al cargar detalles de receta: $error");
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Error al cargar la receta'),
                                          ),
                                        );
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            // ingredientesUnicos es la lista de ingredientes faltantes
                            await _mostrarDialogoIntervalo(ingredientesUnicos);
                          },
                          child: const Text('Recibir recordatorios'),
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
}