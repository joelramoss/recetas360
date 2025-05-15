import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Import Google Sign-In
import 'package:recetas360/pagines/PaginaLogin.dart'; // Corrected import name
import 'package:recetas360/pagines/PantallaPrincipal.dart'; // Corrected import name
import 'package:flutter_animate/flutter_animate.dart'; // Import animate

// Current User's Login: joelramoss
// Current Date and Time (UTC - YYYY-MM-DD HH:MM:SS formatted): 2025-04-24 14:38:21

class PaginaRegistro extends StatefulWidget {
  const PaginaRegistro({super.key});

  @override
  State<PaginaRegistro> createState() => _PaginaRegistroState();
}

class _PaginaRegistroState extends State<PaginaRegistro> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(); // Instance for Google Sign-In

  bool _isRegistering = false; // Flag for registration progress
  bool _obscurePassword = true; // Toggle password visibility

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  // Registration Logic (with improved error handling and progress state)
  Future<void> _registrarUsuario() async {
    if (_isRegistering) return; // Prevent multiple attempts

    // Hide keyboard
    FocusScope.of(context).unfocus();

    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String name = nameController.text.trim();

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Por favor, completa todos los campos.", style: TextStyle(color: Theme.of(context).colorScheme.onError)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isRegistering = true);

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      String uid = userCredential.user!.uid;

      // Store user data in Firestore
      await _firestore.collection('usuarios').doc(uid).set({
        'uid': uid,
        'nombre': name,
        'email': email,
        'fecha_creacion': FieldValue.serverTimestamp(),
        // Add other fields if needed
      });

      if (!mounted) return; // Check if widget is still mounted

      // Navigate to main screen on success
      Navigator.pushAndRemoveUntil( // Clear navigation stack
        context,
        MaterialPageRoute(builder: (_) => const Pantallaprincipal()),
        (route) => false, // Remove all previous routes
      );

    } on FirebaseAuthException catch (e) {
      if (!mounted) return; // Check again after async operation

      String mensajeError = "Error desconocido al registrar.";
      if (e.code == 'email-already-in-use') {
        mensajeError = "Este correo electrónico ya está en uso.";
      } else if (e.code == 'invalid-email') {
        mensajeError = "El formato del correo electrónico no es válido.";
      } else if (e.code == 'weak-password') {
        mensajeError = "La contraseña es demasiado débil (mínimo 6 caracteres).";
      } else if (e.code == 'operation-not-allowed') {
         mensajeError = "El registro por correo/contraseña no está habilitado.";
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
       print("Generic Error during registration: $e");
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text("Ocurrió un error inesperado.", style: TextStyle(color: Theme.of(context).colorScheme.onError)),
           backgroundColor: Theme.of(context).colorScheme.error,
         ),
       );
    } finally {
      if (mounted) {
        setState(() => _isRegistering = false); // Reset flag
      }
    }
  }

  // Google Sign-In / Registration Logic
  Future<void> _signInWithGoogle() async {
    if (_isRegistering) return;
    setState(() => _isRegistering = true);
    final colorScheme = Theme.of(context).colorScheme;

    try {
      // Trigger the Google authentication flow.
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // Obtain the auth details from the request.
      if (googleUser == null) {
        // User cancelled the sign-in
        if (mounted) setState(() => _isRegistering = false);
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential for Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Check if it's a new user (first time signing in with Google)
        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
          // Store user data in Firestore for new users
          await _firestore.collection('usuarios').doc(user.uid).set({
            'uid': user.uid,
            'nombre': user.displayName ?? 'Usuario Google', // Use Google display name
            'email': user.email ?? '', // Use Google email
            'fecha_creacion': FieldValue.serverTimestamp(),
            // Add other fields if needed, e.g., photoURL: user.photoURL
          });
        }
        // For both new and existing Google users, navigate to main screen
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const Pantallaprincipal()),
          (route) => false,
        );
      } else {
         // Handle case where user is null after sign-in (should be rare)
         throw Exception("Usuario nulo después del inicio de sesión con Google.");
      }

    } catch (e) {
      print("Error during Google Sign-In/Registration: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al iniciar sesión con Google.", style: TextStyle(color: colorScheme.onError)),
          backgroundColor: colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isRegistering = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // Use theme background color - remove Container with gradient
      // backgroundColor: colorScheme.background,
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
                  "Crear Cuenta",
                  textAlign: TextAlign.center,
                  style: textTheme.displaySmall?.copyWith( // Use a display style
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 8),
                Text(
                  "Únete a Recetas 360",
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 35),

                // --- Form Fields ---
                TextFormField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration(
                      context: context,
                      label: 'Nombre completo',
                      icon: Icons.person_outline),
                  validator: (value) => value == null || value.isEmpty ? 'Ingresa tu nombre' : null,
                  enabled: !_isRegistering, // Disable while registering
                ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),
                const SizedBox(height: 16),

                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(
                      context: context,
                      label: 'Correo electrónico',
                      icon: Icons.email_outlined),
                  validator: (value) {
                     if (value == null || value.isEmpty) return 'Ingresa tu correo';
                     // Basic email format check (consider a more robust regex)
                     if (!value.contains('@') || !value.contains('.')) return 'Correo no válido';
                     return null;
                  },
                  enabled: !_isRegistering,
                ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),
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
                   validator: (value) => value == null || value.length < 6 ? 'Mínimo 6 caracteres' : null,
                   enabled: !_isRegistering,
                ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1),
                const SizedBox(height: 25),

                // --- Register Button ---
                ElevatedButton(
                  // Disable button while registering
                  onPressed: _isRegistering ? null : _registrarUsuario,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16), // Adjust padding
                    // backgroundColor: colorScheme.primary, // Uses theme default
                    // foregroundColor: colorScheme.onPrimary,
                  ),
                  child: _isRegistering
                      ? SizedBox( // Show progress indicator
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : const Text(
                          'REGISTRARSE',
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
                        "O regístrate con",
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
                    _socialIcon(context, Icons.alternate_email, "Google", _signInWithGoogle), // Updated Google Icon
                  ],
                ).animate(delay: 800.ms).fadeIn().scale(begin: const Offset(0.8, 0.8)),
                const SizedBox(height: 35),

                // --- Login Link ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "¿Ya tienes cuenta? ",
                      style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    // Use TextButton for clearer interaction
                    TextButton(
                       onPressed: _isRegistering ? null : () { // Disable if registering
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const Paginalogin()),
                        );
                      },
                      child: Text(
                        "Inicia Sesión",
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

  // --- Helper for Input Decoration (Using Theme) ---
  InputDecoration _inputDecoration({
    required BuildContext context,
    required String label,
    required IconData icon,
    Widget? suffixIcon, // Make suffixIcon optional
  }) {
     final theme = Theme.of(context);
     // Use theme's inputDecorationTheme as base
     return InputDecoration(
      labelText: label,
      // labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant), // Uses theme default
      prefixIcon: Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 20),
      suffixIcon: suffixIcon, // Add suffix icon if provided
      // filled: true, // Controlled by theme's inputDecorationTheme
      // fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.5), // Example fill
      // border: OutlineInputBorder( // Controlled by theme
      //   borderRadius: BorderRadius.circular(30),
      //   borderSide: BorderSide.none,
      // ),
      // enabledBorder: OutlineInputBorder( // Controlled by theme
      //   borderRadius: BorderRadius.circular(30),
      //   borderSide: BorderSide(color: theme.colorScheme.outline),
      // ),
      // focusedBorder: OutlineInputBorder( // Controlled by theme
      //   borderRadius: BorderRadius.circular(30),
      //   borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      // ),
    );
  }

  // --- Helper for Social Icons (Using Theme) ---
  Widget _socialIcon(BuildContext context, IconData icon, String tooltip, VoidCallback? onTapAction) { // Added onTapAction parameter
     final colorScheme = Theme.of(context).colorScheme;
     return Tooltip( // Add tooltip for accessibility
       message: "Registrarse con $tooltip",
       child: InkWell(
         // Use the passed function, disable if registering or no function provided
         onTap: _isRegistering || onTapAction == null ? null : onTapAction,
         borderRadius: BorderRadius.circular(25),
         child: Container(
           width: 50,
           height: 50,
           decoration: BoxDecoration(
             // Use surface variant or outline for background/border
             color: colorScheme.surfaceContainerHighest.withOpacity(0.8),
             shape: BoxShape.circle,
             border: Border.all(color: colorScheme.outlineVariant, width: 1),
           ),
           child: Icon(
             icon,
             color: colorScheme.primary, // Use primary color for icon
             size: 24,
           ),
         ),
       ),
     );
  }
}