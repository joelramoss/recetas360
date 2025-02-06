import 'package:flutter/material.dart';



class Editarusuario extends StatelessWidget {
  const Editarusuario({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo blanco para un estilo minimalista
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Cuenta',
          style: TextStyle(
            color: Colors.black, // Texto negro
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.black, // Íconos en negro
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            // Padding para que el contenido no toque los bordes de la pantalla
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: Container(
                width: 320, // Ancho fijo para el formulario
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white, // Fondo blanco para el contenedor
                  border: Border.all(
                    color: Colors.black.withOpacity(0.2),
                  ),
                  borderRadius: BorderRadius.zero, // Bordes cuadrados
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Círculo para añadir o cambiar la imagen
                    GestureDetector(
                      onTap: () {
                        // Aquí puedes añadir la acción para seleccionar o cambiar la imagen
                      },
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.black.withOpacity(0.1),
                        child: const Icon(
                          Icons.add_a_photo,
                          size: 40,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Campo de texto para "Nombre de usuario" con ícono de usuario
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Nombre de usuario',
                        labelStyle: const TextStyle(color: Colors.black),
                        prefixIcon: const Icon(
                          Icons.person,
                          color: Colors.black,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(
                            color: Colors.black.withOpacity(0.3),
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Campo de texto para "Password" con ícono de llave
                    TextField(
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: const TextStyle(color: Colors.black),
                        prefixIcon: const Icon(
                          Icons.lock,
                          color: Colors.black,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(
                            color: Colors.black.withOpacity(0.3),
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Texto que indica "Aplicar cambios"
                    const Text(
                      'Aplicar cambios',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Botón para aplicar los cambios
                    ElevatedButton(
                      onPressed: () {
                        // Acción para aplicar los cambios
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
                        'Aplicar',
                        style: TextStyle(
                          color: Colors.white, // Texto blanco
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
      ),
    );
  }
}
