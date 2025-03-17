import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Opcional: para guardar más datos en Firestore
import 'package:recetas360/pagines/PaginaLogin.dart';
import 'package:recetas360/pagines/PantallaPrincipal.dart';

/// OLA INFERIOR #1 (fondo rosa)
class PinkWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(
      size.width * 0.25, size.height * 0.80,
      size.width * 0.50, size.height * 0.90,
    );
    path.quadraticBezierTo(
      size.width * 0.75, size.height,
      size.width, size.height * 0.70,
    );
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
    path.moveTo(0, size.height * 0.95);
    path.quadraticBezierTo(
      size.width * 0.25, size.height * 0.75,
      size.width * 0.50, size.height * 0.85,
    );
    path.quadraticBezierTo(
      size.width * 0.75, size.height * 0.95,
      size.width, size.height * 0.60,
    );
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
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  // Campo opcional para nombre u otro dato:
  final TextEditingController nameController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Opcional: para guardar más datos en Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool rememberMe = false;

  @override
  void initState() {
    super.initState();
    emailController.addListener(_onTextFieldChange);
    passwordController.addListener(_onTextFieldChange);
    nameController.addListener(_onTextFieldChange);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  void _onTextFieldChange() {
    setState(() {});
  }

  Future<void> _registrarUsuario() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String name = nameController.text.trim();

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, completa todos los campos.")),
      );
      return;
    }

    try {
      // Crear usuario en Firebase Authentication
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(email: email, password: password);
      String uid = userCredential.user!.uid;

      // Opcional: guardar datos adicionales en Firestore
      await _firestore.collection('usuarios').doc(uid).set({
        'uid': uid,
        'nombre': name,
        'email': email,
        'fecha_creacion': FieldValue.serverTimestamp(),
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Pantallaprincipal()),
      );
    } on FirebaseAuthException catch (e) {
      String mensajeError = "Error al registrar usuario.";
      if (e.code == 'email-already-in-use') {
        mensajeError = "Este correo ya está registrado.";
      } else if (e.code == 'invalid-email') {
        mensajeError = "Correo inválido.";
      } else if (e.code == 'weak-password') {
        mensajeError = "La contraseña es demasiado débil.";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool camposLlenos = emailController.text.isNotEmpty &&
        passwordController.text.isNotEmpty &&
        nameController.text.isNotEmpty;

    // Degradado condicional para el botón
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

            // Campo "Nombre completo"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre completo',
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
                    borderSide: BorderSide(
                        color: Colors.purple.shade200, width: 1),
                    borderRadius: BorderRadius.circular(30),
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
                  onPressed: _registrarUsuario,
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

            // "¿Ya tienes cuenta? ¡Inicia Sesión!" -> Navega a PaginaLogin
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