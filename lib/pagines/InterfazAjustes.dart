import 'package:flutter/material.dart';
import 'package:recetas360/pagines/Ajustes/EditarUsuario.dart';
import 'package:recetas360/pagines/Ajustes/Lenguajes.dart';
import 'package:recetas360/pagines/Ajustes/Notificaciones.dart'; // Se asume que este archivo define PaginaNotificaciones
import 'package:recetas360/pagines/PaginaLogin.dart'; // Importa la página de login

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
                        color: Colors.white,
                        borderRadius: BorderRadius.zero, // Bordes cuadrados
                        border: Border.all(
                          color: Colors.black.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Opción: Editar Usuario
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
                          
                          // Opción: Notificaciones
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
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PaginaNotificaciones(),
                                ),
                              );
                            },
                          ),
                          const Divider(color: Colors.black26),
                          
                          // Opción: Lenguaje
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
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const Lenguajes(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          
                          // Botón "Salir" que navega a PaginaLogin.dart
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const Paginalogin(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black, // Botón negro
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 40),
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
