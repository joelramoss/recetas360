import 'package:flutter/material.dart';
import 'package:recetas360/pagines/Ajustes/EditarUsuario.dart';
import 'package:recetas360/pagines/Ajustes/Lenguajes.dart';
import 'package:recetas360/pagines/Ajustes/Notificaciones.dart';
import 'package:recetas360/pagines/PaginaLogin.dart';

class PaginaAjustes extends StatelessWidget {
  const PaginaAjustes({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo degradado para toda la pantalla
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orangeAccent,
              Colors.pink.shade100,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Encabezado de 50 px con texto centrado
              Container(
                width: double.infinity,
                height: 50,
                alignment: Alignment.center,
                child: const Text(
                  "Ajustes",
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
              // Contenedor central con Card para el contenido de ajustes
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Container(
                      width: 320,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(2, 2),
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Opción: Editar Usuario
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.person, color: Colors.black),
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
                            leading: const Icon(Icons.notifications, color: Colors.black),
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
                            leading: const Icon(Icons.language, color: Colors.black),
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
                          // Botón "Salir"
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
                              backgroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Salir',
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
            ],
          ),
        ),
      ),
    );
  }
}
