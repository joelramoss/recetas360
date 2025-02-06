import 'package:flutter/material.dart';
// Asegúrate de tener la ruta correcta para la página de ajustes si deseas importarla
// import 'package:recetas360/pagines/EditarUsuario.dart';

class PaginaNotificaciones extends StatefulWidget {
  const PaginaNotificaciones({Key? key}) : super(key: key);

  @override
  State<PaginaNotificaciones> createState() => _PaginaNotificacionesState();
}

class _PaginaNotificacionesState extends State<PaginaNotificaciones> {
  bool _activarNotificaciones = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fondo blanco para mantener el estilo minimalista
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Notificaciones",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        // Botón de retroceso para volver a la página de Ajustes
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: Container(
                      width: 320, // Ancho similar al contenedor de la interfaz de ajustes
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.zero, // Bordes cuadrados
                        border: Border.all(
                          color: Colors.black.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '¿Desea activar las notificaciones?',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          // Fila que contiene el texto "No", el Switch y el texto "Si"
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "No",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Switch(
                                value: _activarNotificaciones,
                                onChanged: (bool value) {
                                  setState(() {
                                    _activarNotificaciones = value;
                                  });
                                },
                                activeColor: Colors.black,
                                inactiveThumbColor: Colors.black,
                                inactiveTrackColor: Colors.black26,
                              ),
                              const Text(
                                "Si",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Botón para volver a la interfaz de ajustes
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context); // Vuelve a la página anterior (Interfaz de Ajustes)
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                            child: const Text(
                              'Volver',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
