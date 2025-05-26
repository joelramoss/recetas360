import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Import Google Sign-In
import 'package:recetas360/pagines/PaginaLogin.dart';
import 'package:recetas360/pagines/PantallaPrincipal.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PaginaRegistro extends StatefulWidget {
  const PaginaRegistro({super.key});

  @override
  State<PaginaRegistro> createState() => _PaginaRegistroState();
}

class _PaginaRegistroState extends State<PaginaRegistro> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController nameController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool _isRegistering = false;
  bool _obscurePassword = true;

  // Flags de validación de la contraseña
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasDigit = false;
  bool _hasSpecialChar = false;
  bool _passwordsMatch = false;

  @override
  void initState() {
    super.initState();
    passwordController.addListener(_validatePassword);
    confirmPasswordController.addListener(_validatePasswordsMatch);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  void _validatePassword() {
    final value = passwordController.text;
    setState(() {
      _hasMinLength = value.length >= 8;
      _hasUppercase = RegExp(r'[A-Z]').hasMatch(value);
      _hasLowercase = RegExp(r'[a-z]').hasMatch(value);
      _hasDigit = RegExp(r'\d').hasMatch(value);
      _hasSpecialChar = RegExp(r'[!@#\$%^&*(),.?":{}|<>_-]').hasMatch(value);
    });
    _validatePasswordsMatch();
  }

  void _validatePasswordsMatch() {
    setState(() {
      _passwordsMatch =
          passwordController.text == confirmPasswordController.text &&
              confirmPasswordController.text.isNotEmpty;
    });
  }

  Future<void> _registrarUsuario() async {
    if (_isRegistering) return;
    FocusScope.of(context).unfocus();

    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String name = nameController.text.trim();

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Por favor, completa todos los campos.",
              style: TextStyle(color: Theme.of(context).colorScheme.onError)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Validar criterios de contraseña antes de Firebase
    if (!_hasMinLength ||
        !_hasUppercase ||
        !_hasLowercase ||
        !_hasDigit ||
        !_hasSpecialChar) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("La contraseña no cumple todos los requisitos.",
              style: TextStyle(color: Theme.of(context).colorScheme.onError)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    if (!_passwordsMatch) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Las contraseñas no coinciden.",
              style: TextStyle(color: Theme.of(context).colorScheme.onError)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isRegistering = true);

    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      String uid = userCredential.user!.uid;

      await _firestore.collection('usuarios').doc(uid).set({
        'uid': uid,
        'nombre': name,
        'email': email,
        'fecha_creacion': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Pantallaprincipal()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String mensajeError = "Error desconocido al registrar.";
      if (e.code == 'email-already-in-use') {
        mensajeError = "Este correo electrónico ya está en uso.";
      } else if (e.code == 'invalid-email') {
        mensajeError = "El formato del correo electrónico no es válido.";
      } else if (e.code == 'weak-password') {
        mensajeError =
            "La contraseña es demasiado débil (mínimo 6 caracteres).";
      } else if (e.code == 'operation-not-allowed') {
        mensajeError = "El registro por correo/contraseña no está habilitado.";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensajeError,
              style: TextStyle(color: Theme.of(context).colorScheme.onError)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Ocurrió un error inesperado.",
              style: TextStyle(color: Theme.of(context).colorScheme.onError)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isRegistering) return;
    setState(() => _isRegistering = true);
    final colorScheme = Theme.of(context).colorScheme;

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        if (mounted) setState(() => _isRegistering = false);
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
          await _firestore.collection('usuarios').doc(user.uid).set({
            'uid': user.uid,
            'nombre': user.displayName ?? 'Usuario Google',
            'email': user.email ?? '',
            'fecha_creacion': FieldValue.serverTimestamp(),
          });
        }
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const Pantallaprincipal()),
          (route) => false,
        );
      } else {
        throw Exception(
            "Usuario nulo después del inicio de sesión con Google.");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al iniciar sesión con Google.",
              style: TextStyle(color: colorScheme.onError)),
          backgroundColor: colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  Widget _buildCriteriaRow(String label, bool passed) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(
          passed ? Icons.check_circle : Icons.cancel,
          size: 18,
          color: passed ? Colors.green : cs.error,
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required BuildContext context,
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      prefixIcon:
          Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 20),
      suffixIcon: suffixIcon,
    );
  }

  Widget _socialIcon(BuildContext context, IconData icon, String tooltip,
      VoidCallback? onTapAction) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: "Registrarse con $tooltip",
      child: InkWell(
        onTap: _isRegistering || onTapAction == null ? null : onTapAction,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withOpacity(0.8),
            shape: BoxShape.circle,
            border: Border.all(color: cs.outlineVariant, width: 1),
          ),
          child: Icon(icon, color: cs.primary, size: 24),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Crear Cuenta",
                  textAlign: TextAlign.center,
                  style: tt.displaySmall?.copyWith(
                      color: cs.primary, fontWeight: FontWeight.bold),
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 8),
                Text(
                  "Únete a Recetas 360",
                  textAlign: TextAlign.center,
                  style: tt.titleMedium?.copyWith(color: cs.onSurfaceVariant),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 35),

                TextFormField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration(
                      context: context,
                      label: 'Nombre completo',
                      icon: Icons.person_outline),
                  enabled: !_isRegistering,
                ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),
                const SizedBox(height: 16),

                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(
                      context: context,
                      label: 'Correo electrónico',
                      icon: Icons.email_outlined),
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
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: cs.onSurfaceVariant,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  enabled: !_isRegistering,
                ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1),
                const SizedBox(height: 8),

                // Criterios de contraseña
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCriteriaRow('8 o más caracteres', _hasMinLength),
                    _buildCriteriaRow('Una mayúscula', _hasUppercase),
                    _buildCriteriaRow('Una minúscula', _hasLowercase),
                    _buildCriteriaRow('Un dígito', _hasDigit),
                    _buildCriteriaRow('Un carácter especial', _hasSpecialChar),
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: _obscurePassword,
                  decoration: _inputDecoration(
                    context: context,
                    label: 'Confirmar contraseña',
                    icon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: cs.onSurfaceVariant,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  enabled: !_isRegistering,
                ),
                const SizedBox(height: 8),

                // Indicador de match
                Row(
                  children: [
                    Icon(
                      _passwordsMatch ? Icons.check_circle : Icons.cancel,
                      size: 18,
                      color: _passwordsMatch ? Colors.green : cs.error,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _passwordsMatch
                          ? 'Las contraseñas coinciden'
                          : 'Las contraseñas no coinciden',
                      style: tt.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                ElevatedButton(
                  onPressed: _isRegistering ? null : _registrarUsuario,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isRegistering
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: cs.onPrimary,
                          ),
                        )
                      : const Text('REGISTRARSE'),
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
                const SizedBox(height: 30),

                Row(
                  children: [
                    Expanded(child: Divider(color: cs.outlineVariant)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Text(
                        "O regístrate con",
                        style:
                            tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ),
                    Expanded(child: Divider(color: cs.outlineVariant)),
                  ],
                ).animate().fadeIn(delay: 700.ms),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _socialIcon(context, Icons.alternate_email, "Google",
                        _signInWithGoogle),
                  ],
                )
                    .animate(delay: 800.ms)
                    .fadeIn()
                    .scale(begin: const Offset(0.8, 0.8)),
                const SizedBox(height: 35),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "¿Ya tienes cuenta? ",
                      style:
                          tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    TextButton(
                      onPressed: _isRegistering
                          ? null
                          : () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const Paginalogin()),
                              );
                            },
                      child: Text(
                        "Inicia Sesión",
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 900.ms),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
