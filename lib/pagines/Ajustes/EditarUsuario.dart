import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Import animate


class Editarusuario extends StatefulWidget {
  const Editarusuario({super.key});

  @override
  _EditarusuarioState createState() => _EditarusuarioState();
}

class _EditarusuarioState extends State<Editarusuario> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // Add form key

  bool _isLoading = true; // Start loading initially
  bool _isSaving = false; // Separate flag for saving state

  String _userInitial = "?"; // Store user initial

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // --- Load User Data ---
  Future<void> _loadUserData() async {
    // No need to set _isLoading = true here, already set in initial state
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // Handle user not logged in case
       if (mounted) {
         setState(() => _isLoading = false);
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('No se pudo encontrar el usuario.', style: TextStyle(color: Theme.of(context).colorScheme.onError)), backgroundColor: Theme.of(context).colorScheme.error),
         );
         // Optionally pop the screen
         // Navigator.pop(context);
       }
      return;
    }

    try {
      // Set email and initial from Auth
      _emailController.text = currentUser.email ?? '';
      _userInitial = currentUser.displayName?.substring(0, 1).toUpperCase() ?? currentUser.email?.substring(0, 1).toUpperCase() ?? "?";


      // Fetch additional data from Firestore
      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(currentUser.uid).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        _nombreController.text = data['nombre'] ?? currentUser.displayName ?? ''; // Fallback to Auth display name
        // Update initial if name exists in Firestore
        if (_nombreController.text.isNotEmpty) {
           _userInitial = _nombreController.text.substring(0, 1).toUpperCase();
        }
      } else {
         // If no Firestore data, use Auth display name if available
         _nombreController.text = currentUser.displayName ?? '';
      }

    } catch (e) {
      print("Error loading user data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: ${e.toString()}', style: TextStyle(color: Theme.of(context).colorScheme.onError)), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- Update User Data ---
  Future<void> _updateUserData() async {
    if (_isSaving) return;
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }
    // Hide keyboard
    FocusScope.of(context).unfocus();

    setState(() => _isSaving = true);
    final newName = _nombreController.text.trim();
    final colorScheme = Theme.of(context).colorScheme;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception("Usuario no autenticado.");

      // --- Update Firestore (if name changed) ---
      // Only update if the name actually changed to avoid unnecessary writes
      final currentFirestoreData = await FirebaseFirestore.instance.collection('usuarios').doc(currentUser.uid).get();
      final currentFirestoreName = (currentFirestoreData.data())?['nombre'] as String?;

      if (currentFirestoreName != newName) {
         await FirebaseFirestore.instance.collection('usuarios').doc(currentUser.uid).set(
            {'nombre': newName}, SetOptions(merge: true)); // Use set with merge to create if not exists
      }


      // --- Update Auth Display Name (if changed) ---
      if (currentUser.displayName != newName) {
         await currentUser.updateDisplayName(newName);
         // Optional: Reload user data to reflect changes immediately in Auth state
         // await currentUser.reload();
      }


      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Datos actualizados correctamente!')),
      );
      Navigator.pop(context); // Go back after saving

    } catch (e) {
       print("Error updating user data: $e");
       if (!mounted) return;
       String errorMsg = 'Error al actualizar datos.';
       if (e is FirebaseAuthException) {
         errorMsg = 'Error de autenticación: ${e.message ?? e.code}';
       }
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(errorMsg, style: TextStyle(color: colorScheme.onError)), backgroundColor: colorScheme.error),
       );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

   // --- Send Password Reset ---
   Future<void> _sendPasswordReset() async {
     final email = _emailController.text.trim();
     if (email.isEmpty) return; // Should not happen if loaded correctly

     final colorScheme = Theme.of(context).colorScheme;

     try {
       await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
       if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(
           content: Text('Enlace de restablecimiento enviado a tu correo'),
           // backgroundColor: Colors.green, // Use default theme indication
         ),
       );
     } catch (e) {
       print("Error sending password reset email: $e");
       if (!mounted) return;
        String errorMsg = 'Error al enviar correo de restablecimiento.';
       if (e is FirebaseAuthException) {
         errorMsg = 'Error: ${e.message ?? e.code}';
       }
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text(errorMsg, style: TextStyle(color: colorScheme.onError)),
           backgroundColor: colorScheme.error,
         ),
       );
     }
   }


  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Perfil"),
        // backgroundColor: colorScheme.surface, // Uses theme default
      ),
      // Removed Container with gradient
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Themed indicator
          : SafeArea(
              child: ListView( // Use ListView for better scrolling if content grows
                padding: const EdgeInsets.all(16.0),
                children: [
                  Form( // Wrap form fields
                    key: _formKey,
                    child: Column(
                      children: [
                         // --- User Avatar ---
                         CircleAvatar(
                          radius: 50,
                          backgroundColor: colorScheme.primaryContainer,
                          foregroundColor: colorScheme.onPrimaryContainer,
                          child: Text(
                            _userInitial, // Display initial loaded
                            style: textTheme.headlineLarge?.copyWith(color: colorScheme.onPrimaryContainer),
                          ),
                        ).animate().fadeIn(delay: 100.ms).scale(),
                        const SizedBox(height: 24),

                        // --- Name Field ---
                        TextFormField(
                          controller: _nombreController,
                          decoration: _inputDecoration( // Use helper
                              context: context,
                              label: 'Nombre',
                              icon: Icons.person_outline_rounded),
                          validator: (value) => value == null || value.trim().isEmpty ? 'El nombre no puede estar vacío' : null,
                           enabled: !_isSaving, // Disable while saving
                           textCapitalization: TextCapitalization.words,
                        ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
                        const SizedBox(height: 16),

                        // --- Email Field (Read-only) ---
                        TextFormField(
                          controller: _emailController,
                          enabled: false, // Always disabled
                          style: TextStyle(color: colorScheme.onSurfaceVariant), // Dim text color
                          decoration: _inputDecoration(
                            context: context,
                            label: 'Correo electrónico',
                            icon: Icons.email_outlined,
                          ).copyWith( // Customize disabled appearance
                             fillColor: colorScheme.onSurface.withOpacity(0.04), // Slightly different background when disabled
                             filled: true,
                          ),
                        ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),
                        const SizedBox(height: 24),

                        // --- Reset Password Button ---
                         TextButton.icon(
                          onPressed: _isSaving ? null : _sendPasswordReset, // Disable while saving
                          icon: Icon(Icons.lock_reset_rounded, color: colorScheme.secondary),
                          label: Text(
                            'Restablecer contraseña por correo',
                            style: TextStyle(color: colorScheme.secondary),
                          ),
                        ).animate().fadeIn(delay: 400.ms),
                        const SizedBox(height: 32),

                        // --- Save Button ---
                        ElevatedButton(
                          onPressed: _isSaving ? null : _updateUserData, // Disable while saving
                           style: ElevatedButton.styleFrom(
                             minimumSize: const Size(double.infinity, 50), // Make button wider
                           ),
                          child: _isSaving
                              ? SizedBox( // Show progress indicator
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: colorScheme.onPrimary,
                                  ),
                                )
                              : const Text('Guardar Cambios'),
                        ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

   // --- Helper for Input Decoration (Using Theme) ---
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