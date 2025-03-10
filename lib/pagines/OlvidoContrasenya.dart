import 'package:flutter/material.dart';
import 'package:recetas360/pagines/PaginaLogin.dart'; // Import de la página de login

/// OLA INFERIOR #1 (fondo rosa)
class PinkWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    // Comienza desde la esquina inferior izquierda
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

    // Cierra el contorno hasta la esquina inferior derecha
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
    // Inicia un poco más arriba para superponer la ola rosa
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

    // Cierra el contorno hasta la esquina inferior derecha
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(PurpleWaveClipper oldClipper) => false;
}

class OlvidoContrasenya extends StatefulWidget {
  const OlvidoContrasenya({Key? key}) : super(key: key);

  @override
  State<OlvidoContrasenya> createState() => _OlvidoContrasenyaState();
}

class _OlvidoContrasenyaState extends State<OlvidoContrasenya> {
  final TextEditingController emailController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Verificamos si hay texto en el campo para decidir el degradado del botón
    final bool emailNotEmpty = emailController.text.isNotEmpty;

    // Definimos el degradado del botón
    final List<Color> gradientColors = emailNotEmpty
        ? [Colors.pink.shade300, Colors.pink.shade100]
        : [Colors.pink.shade100, Colors.pink.shade100];

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 60),
            // Título principal
            const Text(
              "Olvidaste la contraseña",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            // Subtítulo con instrucciones traducido al español
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Por favor, ingresa tu correo y te enviaremos un enlace para restablecer tu contraseña",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Campo "Ingresa tu correo"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: emailController,
                onChanged: (_) => setState(() {}), // Para refrescar el degradado
                decoration: InputDecoration(
                  labelText: 'Ingresa tu correo',
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
            const SizedBox(height: 40),
            // Botón "RESET PASSWORD" con degradado
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (emailNotEmpty) {
                      // Lógica para enviar el enlace de recuperación
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text("Se ha enviado un enlace de recuperación a tu correo."),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Por favor, ingresa tu correo."),
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
                        'RESET PASSWORD',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            // "Have an Account? Sign in"
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "¿Tienes cuenta? ",
                  style: TextStyle(color: Colors.grey),
                ),
                GestureDetector(
                  onTap: () {
                    // Navegar a la pantalla de login
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const Paginalogin(),
                      ),
                    );
                  },
                  child: const Text(
                    "Loguetate",
                    style: TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            // Waves (olas) en la parte inferior
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
}
