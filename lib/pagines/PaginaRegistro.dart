import 'package:flutter/material.dart';
import 'package:recetas360/pagines/PantallaPrincipal.dart';
import 'package:recetas360/pagines/PaginaLogin.dart'; // Importa la página de login

/// OLA INFERIOR #1 (fondo rosa)
class PinkWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    // Empezamos desde la esquina inferior izquierda
    path.moveTo(0, size.height);

    // Primer arco (sube)
    path.quadraticBezierTo(
      size.width * 0.25,  // Punto de control X
      size.height * 0.80, // Punto de control Y
      size.width * 0.50,  // Destino X
      size.height * 0.90, // Destino Y
    );

    // Segundo arco (baja)
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height,
      size.width,
      size.height * 0.70,
    );

    // Cierra hasta la esquina inferior derecha
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(PinkWaveClipper oldClipper) => false;
}

/// OLA INFERIOR #2 (encima, morada)
class PurpleWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    // Iniciamos un poco más arriba para superponer la ola rosa
    path.moveTo(0, size.height * 0.95);

    // Primer arco
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.75,
      size.width * 0.50,
      size.height * 0.85,
    );

    // Segundo arco
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.95,
      size.width,
      size.height * 0.60,
    );

    // Cierra hasta la esquina inferior derecha
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(PurpleWaveClipper oldClipper) => false;
}

class PaginaRegistro extends StatefulWidget {
  const PaginaRegistro({Key? key}) : super(key: key);

  @override
  State<PaginaRegistro> createState() => _PaginaRegistroState();
}

class _PaginaRegistroState extends State<PaginaRegistro> {
  bool rememberMe = false;

  // Controladores para campos de texto
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Escuchamos cambios en los campos
    emailController.addListener(_onTextFieldChange);
    passwordController.addListener(_onTextFieldChange);
  }

  @override
  void dispose() {
    // Importante: limpiar los listeners
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _onTextFieldChange() {
    // Cada vez que cambia un texto, se llama setState para refrescar el botón
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Condición para ver si ambos campos están llenos
    final bool camposLlenos = emailController.text.isNotEmpty &&
        passwordController.text.isNotEmpty;

    // Elegimos el color según la condición para el degradado del botón
    final List<Color> gradientColors = camposLlenos
        ? [Colors.pink.shade300, Colors.pink.shade100]
        : [Colors.pink.shade100, Colors.pink.shade100];

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 60),
            // Título "Registrarse"
            const Text(
              "Registrarse",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 30),

            // Campo "Ingresa tu correo electrónico"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Ingresa tu correo electrónico',
                  labelStyle: const TextStyle(color: Colors.black87),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: Colors.purple, width: 2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.purple.shade200, width: 1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Campo "Crea una contraseña"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Crea una contraseña',
                  labelStyle: const TextStyle(color: Colors.black87),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: Colors.purple, width: 2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.purple.shade200, width: 1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Línea "¿Olvidaste tu contraseña?" (opcional)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextButton(
                  onPressed: () {
                    // Acción para recuperar la contraseña
                  },
                  child: const Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(
                      color: Colors.purple,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // "Recuérdame" con Switch (opcional)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Recuérdame"),
                  Switch(
                    activeColor: Colors.purple,
                    value: rememberMe,
                    onChanged: (value) {
                      setState(() {
                        rememberMe = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Botón "REGISTRARSE" con degradado condicional
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (camposLlenos) {
                      // Lógica de registro o navegación
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const Pantallaprincipal(),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Por favor, completa ambos campos."),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: const Text(
                        'REGISTRARSE',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Texto "También puedes registrarte con ..."
            const Text(
              "También puedes registrarte con ...",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Iconos de redes sociales (sin Facebook)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _socialIcon(Icons.alternate_email, Colors.lightBlue), // Twitter
                const SizedBox(width: 20),
                _socialIcon(Icons.g_mobiledata, Colors.red), // Google
              ],
            ),
            const SizedBox(height: 30),

            // "¿Ya tienes cuenta? ¡Inicia Sesión!" -> Navega a PaginaLogin.dart
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "¿Ya tienes cuenta? ",
                  style: TextStyle(color: Colors.grey),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const Paginalogin(),
                      ),
                    );
                  },
                  child: const Text(
                    "¡Inicia Sesión!",
                    style: TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Contenedor para las DOS OLAS
            SizedBox(
              height: 200,
              width: double.infinity,
              child: Stack(
                children: [
                  // OLA ROSA (FONDO)
                  Positioned.fill(
                    child: ClipPath(
                      clipper: PinkWaveClipper(),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFF48FB1), // Rosa claro
                              Color(0xFFF06292)  // Rosa más intenso
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // OLA MORADA (ENCIMA)
                  Positioned.fill(
                    child: ClipPath(
                      clipper: PurpleWaveClipper(),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFBA68C8), // Morado claro
                              Color(0xFF9C27B0)  // Morado más oscuro
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper para iconos de redes sociales
  Widget _socialIcon(IconData icon, Color color) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }
}
