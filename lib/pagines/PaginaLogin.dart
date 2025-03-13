import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recetas360/pagines/OlvidoContrasenya.dart';
import 'package:recetas360/pagines/PantallaPrincipal.dart';
import 'package:recetas360/pagines/PaginaRegistro.dart';

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

class Paginalogin extends StatefulWidget {
  const Paginalogin({Key? key}) : super(key: key);

  @override
  State<Paginalogin> createState() => _PaginaloginState();
}

class _PaginaloginState extends State<Paginalogin> {
  bool rememberMe = false;

  // Controladores para los campos de texto
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    emailController.addListener(_onTextFieldChange);
    passwordController.addListener(_onTextFieldChange);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _onTextFieldChange() {
    setState(() {});
  }

  Future<void> _iniciarSesion() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, completa ambos campos.")),
      );
      return;
    }

    try {
      // Intentar iniciar sesión con Firebase Authentication
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Si el login es exitoso, ir a la pantalla principal
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Pantallaprincipal()),
      );
    } on FirebaseAuthException catch (e) {
      String mensajeError = "Error al iniciar sesión.";
      if (e.code == 'user-not-found') {
        mensajeError = "No existe una cuenta con este correo.";
      } else if (e.code == 'wrong-password') {
        mensajeError = "Contraseña incorrecta.";
      } else if (e.code == 'invalid-email') {
        mensajeError = "Correo inválido.";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool camposLlenos =
        emailController.text.isNotEmpty && passwordController.text.isNotEmpty;

    final Color botonColor = camposLlenos
        ? Colors.pink.shade300 // Más vivo si hay texto
        : Colors.pink.shade100; // Rosa claro si están vacíos

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 60),
            // Título "Iniciar Sesión"
            const Text(
              "Iniciar Sesión",
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
                    borderSide: BorderSide(
                        color: Colors.purple.shade200, width: 1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Campo "Contraseña"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  labelStyle: const TextStyle(color: Colors.black87),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: Colors.purple, width: 2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Colors.purple.shade200, width: 1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Línea "¿Olvidaste tu contraseña?" clicable
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OlvidoContrasenya(),
                      ),
                    );
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

            // "Recuérdame" con Switch
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

            // Botón "INGRESAR" con color condicional
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _iniciarSesion,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    backgroundColor: botonColor,
                  ),
                  child: const Text(
                    'INGRESAR',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Texto "También puedes iniciar sesión con ..."
            const Text(
              "También puedes iniciar sesión con ...",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Iconos de redes sociales (simulados)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _socialIcon(Icons.alternate_email, Colors.lightBlue),
                const SizedBox(width: 20),
                _socialIcon(Icons.g_mobiledata, Colors.red),
              ],
            ),
            const SizedBox(height: 30),

            // "¿Aún no tienes cuenta? ¡Regístrate!" -> Navega a PaginaRegistro
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "¿Aún no tienes cuenta? ",
                  style: TextStyle(color: Colors.grey),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PaginaRegistro(),
                      ),
                    );
                  },
                  child: const Text(
                    "¡Regístrate!",
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