import 'package:flutter/material.dart';
import 'package:recetas360/pagines/PaginaLogin.dart';

class PaginaRegistro extends StatefulWidget {
  const PaginaRegistro({super.key});

  @override
  State<PaginaRegistro> createState() => _PaginaRegistroState();
}

class _PaginaRegistroState extends State<PaginaRegistro> {
  // Controladores para cada campo de texto
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();

  DateTime? _selectedDate;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  // Función para seleccionar la fecha de nacimiento
  Future<void> _selectDate() async {
    DateTime initialDate = _selectedDate ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        // Formateamos la fecha en dd/MM/yyyy
        _birthDateController.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  // Función para procesar el registro (por ahora solo imprime los datos)
  void _register() {
    print("Nombre de usuario: ${_usernameController.text}");
    print("Correo electrónico: ${_emailController.text}");
    print("Contraseña: ${_passwordController.text}");
    print("Fecha de nacimiento: ${_birthDateController.text}");
    // Aquí puedes agregar la lógica de registro necesaria.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fondo blanco para un estilo minimalista
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Recetas360 - Página de Registro",
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
                          // Imagen del logo
                          Image.asset(
                            'assets/images/logo.png',
                            width: 180,
                            height: 180,
                          ),
                          const SizedBox(height: 20),
                          // Título de la pantalla
                          const Text(
                            'Registro',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Icono de registro
                          const Icon(
                            Icons.person_add,
                            size: 50,
                            color: Colors.black,
                          ),
                          const SizedBox(height: 20),
                          // Campo de Nombre de usuario
                          TextField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: 'Nombre de usuario',
                              labelStyle: const TextStyle(color: Colors.black),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.zero, // Bordes cuadrados
                                borderSide: BorderSide(
                                  color: Colors.black
                                      .withOpacity(0.3), // Borde gris
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 15),
                          // Campo de Correo electrónico
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Correo electrónico',
                              labelStyle: const TextStyle(color: Colors.black),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide(
                                  color: Colors.black.withOpacity(0.3),
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 15),
                          // Campo de Contraseña
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              labelStyle: const TextStyle(color: Colors.black),
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
                          // Campo de Fecha de Nacimiento
                          TextField(
                            controller: _birthDateController,
                            decoration: InputDecoration(
                              labelText: 'Fecha de Nacimiento',
                              labelStyle: const TextStyle(color: Colors.black),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide(
                                  color: Colors.black.withOpacity(0.3),
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              suffixIcon: const Icon(
                                Icons.calendar_today,
                                color: Colors.black,
                              ),
                            ),
                            readOnly: true,
                            onTap: _selectDate,
                          ),
                          const SizedBox(height: 20),
                          // Botón de Registro
                          ElevatedButton(
                            onPressed: _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 40),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.zero, // Bordes cuadrados
                              ),
                            ),
                            child: const Text(
                              'Registrar',
                              style: TextStyle(
                                color: Colors.white, // Texto blanco
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          // Botón de Volver
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const Paginalogin(),
                                ),
                              );
                            },
                            child: const Text(
                              'Volver',
                              style: TextStyle(color: Colors.black),
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
