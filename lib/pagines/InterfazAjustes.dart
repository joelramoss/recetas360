import 'package:flutter/material.dart';
import 'package:recetas360/pagines/Ajustes/EditarUsuario.dart'; // Corrected import path
import 'package:recetas360/pagines/PaginaLogin.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:flutter_animate/flutter_animate.dart'; // Import animate

// Current User's Login: joelramoss
// Current Date and Time (UTC - YYYY-MM-DD HH:MM:SS formatted): 2025-04-24 14:44:47

// Renamed file/class to InterfazAjustes based on previous usage, adjust if needed
class PaginaAjustes extends StatelessWidget {
  const PaginaAjustes({super.key});

  // --- Logout Logic ---
  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigate to login screen and remove all previous routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Paginalogin()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      print("Error signing out: $e");
      // Show error message if needed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al cerrar sesión: ${e.toString()}", style: TextStyle(color: Theme.of(context).colorScheme.onError)),
          backgroundColor: Theme.of(context).colorScheme.error,
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
        title: const Text("Ajustes"),
        // backgroundColor: colorScheme.surface, // Uses theme default
        // elevation: 0, // Use theme default elevation
        // Leading back button is added automatically by Navigator
      ),
      // Removed Container with gradient
      body: SafeArea( // Ensure content is within safe area
        child: ListView( // Use ListView for potential future options
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- User Profile Section (Example) ---
             Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ListTile(
                  leading: CircleAvatar( // Display user initial or photo
                     backgroundColor: colorScheme.primaryContainer,
                     foregroundColor: colorScheme.onPrimaryContainer,
                     // TODO: Fetch user data if needed
                     child: Text(FirebaseAuth.instance.currentUser?.displayName?.substring(0, 1).toUpperCase() ?? FirebaseAuth.instance.currentUser?.email?.substring(0, 1).toUpperCase() ?? "?"),
                  ),
                  title: Text(
                    // TODO: Fetch and display user name
                    FirebaseAuth.instance.currentUser?.displayName ?? "Usuario",
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    // TODO: Fetch and display user email
                    FirebaseAuth.instance.currentUser?.email ?? "email@example.com",
                     style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: colorScheme.onSurfaceVariant),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Editarusuario()),
                    );
                  },
                ),
              ),
            ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),

            const SizedBox(height: 24),

            // --- Settings Options ---
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                   _buildSettingsTile(
                     context: context,
                     icon: Icons.person_outline_rounded,
                     title: 'Editar Perfil', // Changed text slightly
                     onTap: () {
                       Navigator.push(
                         context,
                         MaterialPageRoute(builder: (context) => const Editarusuario()),
                       );
                     },
                   ),
                   Divider(height: 1, indent: 16, endIndent: 16, color: colorScheme.outlineVariant.withOpacity(0.5)), // Themed divider
                   _buildSettingsTile(
                     context: context,
                     icon: Icons.notifications_none_rounded,
                     title: 'Notificaciones',
                     onTap: () { /* TODO: Navigate to Notifications settings */
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pantalla de Notificaciones (pendiente)")));
                     },
                   ),
                    Divider(height: 1, indent: 16, endIndent: 16, color: colorScheme.outlineVariant.withOpacity(0.5)),
                    _buildSettingsTile(
                     context: context,
                     icon: Icons.language_rounded,
                     title: 'Idioma',
                      onTap: () { /* TODO: Navigate to Language settings */
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pantalla de Idioma (pendiente)")));
                      },
                   ),
                    Divider(height: 1, indent: 16, endIndent: 16, color: colorScheme.outlineVariant.withOpacity(0.5)),
                     _buildSettingsTile(
                     context: context,
                     icon: Icons.help_outline_rounded,
                     title: 'Ayuda y Soporte',
                     onTap: () { /* TODO: Navigate to Help/Support */
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pantalla de Ayuda (pendiente)")));
                     },
                   ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms), // Animate card

            const SizedBox(height: 32),

            // --- Logout Button ---
            ElevatedButton.icon(
              onPressed: () => _logout(context), // Call logout function
              style: ElevatedButton.styleFrom(
                 // Use error color for logout button background
                backgroundColor: colorScheme.errorContainer,
                foregroundColor: colorScheme.onErrorContainer, // Text/icon color on error container
                minimumSize: const Size(double.infinity, 50), // Make button wider
                // padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Cerrar Sesión'), // Changed text
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2), // Animate button
          ],
        ),
      ),
    );
  }

  // Helper widget for consistent ListTile styling
  Widget _buildSettingsTile({
     required BuildContext context,
     required IconData icon,
     required String title,
     required VoidCallback onTap,
  }) {
     final colorScheme = Theme.of(context).colorScheme;
     final textTheme = Theme.of(context).textTheme;

     return ListTile(
       contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
       leading: Icon(icon, color: colorScheme.primary), // Use primary color for icon
       title: Text(
         title,
         style: textTheme.titleMedium, // Use appropriate text style
       ),
       trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: colorScheme.onSurfaceVariant),
       onTap: onTap,
     );
  }
}