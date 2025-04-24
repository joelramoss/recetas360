import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recetas360/pagines/OlvidoContrasenya.dart'; // Corrected import name
import 'package:recetas360/pagines/PantallaPrincipal.dart'; // Corrected import name
import 'package:recetas360/pagines/PaginaRegistro.dart'; // Corrected import name
import 'package:flutter_animate/flutter_animate.dart'; // Import animate

// Current User's Login: joelramoss
// Current Date and Time (UTC - YYYY-MM-DD HH:MM:SS formatted): 2025-04-24 14:41:09

class Paginalogin extends StatefulWidget {
  const Paginalogin({Key? key}) : super(key: key);

  @override
  State<Paginalogin> createState() => _PaginaloginState();
}

class _PaginaloginState extends State<Paginalogin> {
  // bool rememberMe = false; // Removed, not used
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoggingIn = false; // Flag for login progress
  bool _obscurePassword = true; // Toggle password visibility

  // Removed listeners as they only called setState without specific logic

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Login Logic (with improved error handling and progress state)
  Future<void> _iniciarSesion() async {
    if (_isLoggingIn) return; // Prevent multiple attempts

    // Hide keyboard
    FocusScope.of(context).unfocus();

    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Por favor, completa ambos campos.", style: TextStyle(color: Theme.of(context).colorScheme.onError)),
          backgroundColor: Theme.of(context).colorScheme.error,
          ),
      );
      return;
    }

    setState(() => _isLoggingIn = true);

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      if (!mounted) return; // Check if widget is still mounted

      // Navigate to main screen on success, clearing the stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Pantallaprincipal()),
        (route) => false, // Remove all previous routes
      );

    } on FirebaseAuthException catch (e) {
       if (!mounted) return; // Check again after async operation

      String mensajeError = "Error desconocido al iniciar sesión.";
      if (e.code == 'user-not-found' || e.code == 'invalid-credential' ) { // invalid-credential covers wrong email/pass
        mensajeError = "Correo o contraseña incorrectos.";
      } else if (e.code == 'invalid-email') {
        mensajeError = "El formato del correo electrónico no es válido.";
      } else if (e.code == 'user-disabled') {
         mensajeError = "Esta cuenta ha sido deshabilitada.";
      }
      print("FirebaseAuthException: ${e.code} - ${e.message}"); // Log detailed error

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensajeError, style: TextStyle(color: Theme.of(context).colorScheme.onError)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } catch (e) { // Catch generic errors
       if (!mounted) return;
       print("Generic Error during login: $e");
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text("Ocurrió un error inesperado.", style: TextStyle(color: Theme.of(context).colorScheme.onError)),
           backgroundColor: Theme.of(context).colorScheme.error,
         ),
       );
    } finally {
      if (mounted) {
        setState(() => _isLoggingIn = false); // Reset flag
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Removed dynamic button color based on camposLlenos, button state handled by onPressed

    return Scaffold(
      // Use theme background color - remove Container with gradient
      body: SafeArea( // Ensure content doesn't overlap status bar/notches
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                 // --- App Logo (Optional) ---
                // Icon(Icons.restaurant_menu, size: 60, color: colorScheme.primary),
                // const SizedBox(height: 20),

                // --- Title ---
                Text(
                  "Iniciar Sesión",
                  textAlign: TextAlign.center,
                  style: textTheme.displaySmall?.copyWith( // Use display style
                    color: colorScheme.primary, // Use primary color
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(delay: 100.ms),
                 const SizedBox(height: 8),
                 Text(
                  "Bienvenido de nuevo a Recetas 360",
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 35),

                // --- Form Fields ---
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(
                    context: context,
                    label: 'Correo electrónico',
                    icon: Icons.email_outlined,
                  ),
                   validator: (value) { // Add basic validation
                     if (value == null || value.isEmpty) return 'Ingresa tu correo';
                     if (!value.contains('@') || !value.contains('.')) return 'Correo no válido';
                     return null;
                   },
                   enabled: !_isLoggingIn, // Disable while logging in
                   autovalidateMode: AutovalidateMode.onUserInteraction, // Validate as user types
                ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),
                const SizedBox(height: 16),

                TextFormField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  decoration: _inputDecoration(
                    context: context,
                    label: 'Contraseña',
                    icon: Icons.lock_outline,
                     // Add suffix icon to toggle visibility
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Ingresa tu contraseña' : null,
                  enabled: !_isLoggingIn,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),
                const SizedBox(height: 10),

                // --- Forgot Password Link ---
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    // style: TextButton.styleFrom(padding: EdgeInsets.zero), // Keep default padding
                    onPressed: _isLoggingIn ? null : () { // Disable if logging in
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OlvidoContrasenya()),
                      );
                    },
                    child: Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(
                        color: colorScheme.secondary, // Use secondary color
                        // fontSize: 13, // Use theme default
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 15),

                // --- Login Button ---
                ElevatedButton(
                  onPressed: _isLoggingIn ? null : _iniciarSesion, // Disable button when logging in
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    // backgroundColor: colorScheme.primary, // Uses theme default
                  ),
                  child: _isLoggingIn
                      ? SizedBox( // Show progress indicator
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: colorScheme.onPrimary, // Color for indicator on button
                          ),
                        )
                      : const Text(
                          'INGRESAR',
                          // style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
                const SizedBox(height: 30),

                // --- Divider ---
                Row(
                  children: [
                    Expanded(child: Divider(color: colorScheme.outlineVariant)), // Themed divider
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Text(
                        "O inicia sesión con",
                         style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                    Expanded(child: Divider(color: colorScheme.outlineVariant)),
                  ],
                ).animate().fadeIn(delay: 700.ms),
                const SizedBox(height: 20),

                // --- Social Login Icons ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     _socialIcon(context, Icons.alternate_email, "Google"), // Example: Google
                    const SizedBox(width: 20),
                    _socialIcon(context, Icons.facebook, "Facebook"), // Example: Facebook
                  ].animate(interval: 100.ms).fadeIn(delay: 800.ms).scale(begin: Offset(0.8, 0.8)), // Apply interval to children
                ), // Animate Row container if needed, e.g., .animate().fadeIn(delay: 750.ms)
                const SizedBox(height: 35),

                // --- Sign Up Link ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "¿Aún no tienes cuenta? ",
                      style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                     // Use TextButton for clearer interaction
                    TextButton(
                      onPressed: _isLoggingIn ? null : () { // Disable if logging in
                        Navigator.pushReplacement( // Use replacement to avoid back button to login
                          context,
                          MaterialPageRoute(builder: (_) => const PaginaRegistro()),
                        );
                      },
                      child: Text(
                        "¡Regístrate!",
                         style: TextStyle(
                          color: colorScheme.primary, // Use theme primary color
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 900.ms),
                const SizedBox(height: 20), // Bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }

   // --- Helper for Input Decoration (Using Theme - same as Registro) ---
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
      // Styles like filled, border, etc., are inherited from theme's inputDecorationTheme
    );
  }

  // --- Helper for Social Icons (Using Theme - same as Registro) ---
  Widget _socialIcon(BuildContext context, IconData icon, String tooltip) {
     final colorScheme = Theme.of(context).colorScheme;
     return Tooltip(
       message: "Iniciar sesión con $tooltip",
       child: InkWell(
         onTap: _isLoggingIn ? null : () { // Disable if logging in
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text("Inicio con $tooltip no implementado")),
           );
         },
         borderRadius: BorderRadius.circular(25),
         child: Container(
           width: 50,
           height: 50,
           decoration: BoxDecoration(
             color: colorScheme.surfaceVariant.withOpacity(0.8),
             shape: BoxShape.circle,
             border: Border.all(color: colorScheme.outlineVariant, width: 1),
           ),
           child: Icon(
             icon,
             color: colorScheme.primary,
             size: 24,
           ),
         ),
       ),
     );
  }
}