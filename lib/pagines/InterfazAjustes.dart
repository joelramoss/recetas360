import 'package:flutter/material.dart';
import 'package:recetas360/pagines/EditarUsuario.dart';
import 'package:recetas360/pagines/Notificaciones.dart'; // Se asume que este archivo define PaginaNotificaciones

class PaginaAjustes extends StatelessWidget {
  const PaginaAjustes({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fondo blanco para un estilo minimalista
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Ajustes",
          style: TextStyle(
            color: Colors.black, // Texto negro para un buen contraste
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.black, // Íconos en negro
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  // Padding para que el contenido no toque los bordes de la pantalla
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: Container(
                      width: 320, // Ancho del contenedor de ajustes
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.white, // Fondo blanco para el contenedor
                        borderRadius: BorderRadius.zero, // Bordes cuadrados
                        border: Border.all(
                          color: Colors.black.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Opción: Editar Usuario con ícono y navegación
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.person,
                              color: Colors.black,
                            ),
                            title: const Text(
                              'Editar Usuario',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const Editarusuario(),
                                ),
                              );
                            },
                          ),
                          const Divider(color: Colors.black26),
                          
                          // Opción: Notificaciones con ícono
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.notifications,
                              color: Colors.black,
                            ),
                            title: const Text(
                              'Notificaciones',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: () {
                              // Navega a la página de notificaciones
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PaginaNotificaciones(),
                                ),
                              );
                            },
                          ),
                          const Divider(color: Colors.black26),
                          
                          // Opción: Lenguaje con ícono
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.language,
                              color: Colors.black,
                            ),
                            title: const Text(
                              'Lenguaje',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: () {
                              // Acción para cambiar el lenguaje
                            },
                          ),
                          const SizedBox(height: 20),
                          
                          // Botón de Salir (sin ícono)
                          ElevatedButton(
                            onPressed: () {
                              // Acción para salir
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black, // Botón negro
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero, // Bordes cuadrados
                              ),
                            ),
                            child: const Text(
                              'Salir',
                              style: TextStyle(
                                color: Colors.white, // Texto blanco en el botón negro
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
