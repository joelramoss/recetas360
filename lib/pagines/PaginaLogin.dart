import 'package:flutter/material.dart';
import 'package:recetas360/pagines/PaginaRegister.dart';

class Paginalogin extends StatelessWidget {
  const Paginalogin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fondo blanco para un estilo minimalista
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Recetas360 - Página de Login",
          style: TextStyle(
            color: Colors.black, // Texto negro para un buen contraste
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  // El padding evita que el formulario toque los bordes de la pantalla
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: Container(
                      width: 320, // Ancho del formulario
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.white, // Fondo blanco para el formulario
                        borderRadius: BorderRadius.zero, // Bordes cuadrados
                        border: Border.all(
                          color: Colors.black.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Imagen logo antes del título
                          Image.asset(
                            'assets/images/logo.png',
                            width: 180, // Tamaño del logo
                            height: 180,
                          ),
                          const SizedBox(
                              height:
                                  20), // Espaciado entre la imagen y el título

                          // Título de la pantalla (Bienvenido)
                          const Text(
                            'Bienvenido',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Icono de usuario debajo del título
                          const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.black, // Color negro para el icono
                          ),
                          const SizedBox(height: 20),

                          // Campo de Usuario con borde cuadrado
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'Usuario',
                              labelStyle: const TextStyle(color: Colors.black),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.zero, // Bordes cuadrados
                                borderSide: BorderSide(
                                  color: Colors.black
                                      .withOpacity(0.3), // Borde gris claro
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 15),

                          // Campo de Contraseña con borde cuadrado
                          TextField(
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              labelStyle: const TextStyle(color: Colors.black),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.zero, // Bordes cuadrados
                                borderSide: BorderSide(
                                  color: Colors.black
                                      .withOpacity(0.3), // Borde gris claro
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Botón de Login con bordes cuadrados
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black, // Botón negro
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 40),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.zero, // Bordes cuadrados
                              ),
                            ),
                            child: const Text(
                              'Entrar',
                              style: TextStyle(
                                color: Colors
                                    .white, // Texto blanco en el botón negro
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),

                          // Enlaces de acción
                          Align(
                            alignment: Alignment.center,
                            child: Column(
                              children: [
                                TextButton(
                                  onPressed: () {},
                                  child: const Text(
                                    '¿Perdiste tu contraseña?',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const PaginaRegistro(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    '¿No tienes Cuenta? Regístrate aquí',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                                const SizedBox(height: 15),

                                // Botón de Volver con estilo minimalista y bordes cuadrados
                                TextButton(
                                  onPressed: () {},
                                  child: const Text(
                                    'Volver',
                                    style: TextStyle(color: Colors.black),
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
            );
          },
        ),
      ),
    );
  }
}
