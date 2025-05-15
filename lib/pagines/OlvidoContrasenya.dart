import 'package:flutter/material.dart';
import 'package:recetas360/pagines/PaginaLogin.dart'; // Import de la página de login
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Import animate

// Current User's Login: joelramoss
// Current Date and Time (UTC - YYYY-MM-DD HH:MM:SS formatted): 2025-04-24 14:43:29


/// OLA INFERIOR #1 (Clipper remains the same)
class PinkWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.80, size.width * 0.50, size.height * 0.90);
    path.quadraticBezierTo(size.width * 0.75, size.height, size.width, size.height * 0.70);
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(PinkWaveClipper oldClipper) => false;
}

/// OLA INFERIOR #2 (Clipper remains the same)
class PurpleWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, size.height * 0.95);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.75, size.width * 0.50, size.height * 0.85);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.95, size.width, size.height * 0.60);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(PurpleWaveClipper oldClipper) => false;
}

class OlvidoContrasenya extends StatefulWidget {
  const OlvidoContrasenya({super.key});

  @override
  State<OlvidoContrasenya> createState() => _OlvidoContrasenyaState();
}

class _OlvidoContrasenyaState extends State<OlvidoContrasenya> {
  final TextEditingController emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // Add form key for validation
  bool _isSending = false; // Flag for sending progress

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  // --- Send Reset Email Logic ---
  Future<void> _sendResetEmail() async {
    if (_isSending) return;
    // Validate the form
    if (!_formKey.currentState!.validate()) {
      return;
    }
    // Hide keyboard
    FocusScope.of(context).unfocus();

    setState(() => _isSending = true);
    final email = emailController.text.trim();
    final colorScheme = Theme.of(context).colorScheme; // Get theme for SnackBar

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return; // Check after async operation

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enlace de recuperación enviado a tu correo."),
          // backgroundColor: Colors.green, // Use theme default success indication if any
        ),
      );

      // Navigate back to login after a delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) { // Check again before navigation
           // Pop instead of pushReplacement if coming from login
           if (Navigator.canPop(context)) {
             Navigator.pop(context);
           } else {
             // Fallback if cannot pop (e.g., deep link)
             Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Paginalogin()));
           }
        }
      });

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String mensajeError = "Error al enviar el correo.";
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') { // Treat invalid-credential same as not found here
        mensajeError = "No existe una cuenta con ese correo.";
      } else if (e.code == 'invalid-email') {
        mensajeError = "El formato del correo no es válido.";
      }
       print("FirebaseAuthException (Password Reset): ${e.code} - ${e.message}");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensajeError, style: TextStyle(color: colorScheme.onError)),
          backgroundColor: colorScheme.error,
        ),
      );
    } catch (e) {
       if (!mounted) return;
       print("Generic Error sending password reset: $e");
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text("Ocurrió un error inesperado.", style: TextStyle(color: colorScheme.onError)),
           backgroundColor: colorScheme.error,
         ),
       );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final screenSize = MediaQuery.of(context).size;

    // Removed dynamic gradient logic

    return Scaffold(
      // Add AppBar for navigation context and consistency
      appBar: AppBar(
         title: const Text("Recuperar Contraseña"),
         elevation: 0, // No shadow if waves are below
         backgroundColor: Colors.transparent, // Make AppBar transparent
      ),
      // Extend body behind AppBar to allow waves to potentially go under it
      extendBodyBehindAppBar: true,
      body: Stack( // Use Stack to position waves behind content
        children: [
          // Main content area
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Form( // Wrap content in a Form
                 key: _formKey,
                child: Column(
                  // mainAxisAlignment: MainAxisAlignment.center, // Center vertically is tricky with waves
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: screenSize.height * 0.1), // Space from top
                    // Title
                    Text(
                      "¿Olvidaste tu Contraseña?", // Adjusted title
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium?.copyWith( // Adjusted style
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 12),
                    // Subtitle
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16), // Reduced padding
                      child: Text(
                        "Ingresa tu correo y te enviaremos un enlace para restablecerla.", // Simplified text
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 35),

                    // Email Field
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration( // Use themed helper
                        context: context,
                        label: 'Correo electrónico',
                        icon: Icons.email_outlined,
                      ),
                      validator: (value) { // Add validation
                         if (value == null || value.isEmpty) return 'Ingresa tu correo';
                         if (!value.contains('@') || !value.contains('.')) return 'Correo no válido';
                         return null;
                      },
                      enabled: !_isSending,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),
                    const SizedBox(height: 30),

                    // Reset Button
                    ElevatedButton(
                      onPressed: _isSending ? null : _sendResetEmail, // Disable while sending
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSending
                          ? SizedBox( // Show progress indicator
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : const Text(
                              'ENVIAR ENLACE', // Changed text
                              // style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                    const SizedBox(height: 30),

                    // Back to Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "¿Recordaste tu contraseña? ",
                          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        TextButton(
                          onPressed: _isSending ? null : () { // Disable while sending
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context); // Go back if possible
                            } else {
                              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Paginalogin()));
                            }
                          },
                          child: Text(
                            "Inicia Sesión", // Changed text
                             style: TextStyle(
                              color: colorScheme.primary, // Use theme color
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 500.ms),
                    // Add space to push content above waves, adjust as needed
                    SizedBox(height: screenSize.height * 0.3),
                  ],
                ),
              ),
            ),
          ),

           // --- Waves at the bottom ---
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 200, // Height of the wave area
              width: double.infinity,
              child: Stack(
                children: [
                  // OLA #1 (FONDO) - Use theme color
                  Positioned.fill(
                    child: ClipPath(
                      clipper: PinkWaveClipper(), // Clipper remains the same
                      child: Container(
                        color: colorScheme.primaryContainer.withOpacity(0.5), // Use theme color
                      ),
                    ),
                  ),
                  // OLA #2 (ENCIMA) - Use theme color
                  Positioned.fill(
                    child: ClipPath(
                      clipper: PurpleWaveClipper(), // Clipper remains the same
                      child: Container(
                        color: colorScheme.primary.withOpacity(0.6), // Use theme color
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().slideY(begin: 0.5, delay: 300.ms, duration: 800.ms, curve: Curves.easeOut), // Animate waves sliding up
          ),
        ],
      ),
    );
  }

   // --- Helper for Input Decoration (Using Theme - same as Login/Registro) ---
   InputDecoration _inputDecoration({
    required BuildContext context,
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
     final theme = Theme.of(context);
     return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 20),
      suffixIcon: suffixIcon,
      // Styles inherited from theme's inputDecorationTheme
    );
  }
}