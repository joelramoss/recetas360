import 'package:flutter/material.dart';
import 'package:recetas360/pagines/Ajustes/EditarUsuario.dart';
import 'package:recetas360/pagines/PaginaLogin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:flutter_animate/flutter_animate.dart';

class PaginaAjustes extends StatefulWidget {
  const PaginaAjustes({super.key});

  @override
  State<PaginaAjustes> createState() => _PaginaAjustesState();
}

class _PaginaAjustesState extends State<PaginaAjustes> {
  String _nombreUsuario = "Usuario"; // Valor por defecto o de carga
  String _emailUsuario = "email@example.com";
  String _inicialUsuario = "?";
  bool _cargandoDatos = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    if (!mounted) return;
    setState(() {
      _cargandoDatos = true;
    });

    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      String nombreFirestore = currentUser.displayName ?? "Usuario"; // Fallback inicial
      String email = currentUser.email ?? "email@example.com";
      String inicial = "?";

      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('usuarios').doc(currentUser.uid).get();

        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data() as Map<String, dynamic>;
          if (data.containsKey('nombre') && data['nombre'] != null && (data['nombre'] as String).isNotEmpty) {
            nombreFirestore = data['nombre'];
          }
          // El email de currentUser.email debería ser el más actualizado
          // si se cambió a través de Firebase Auth.
        }
      } catch (e) {
        print("Error al cargar nombre de usuario desde Firestore: $e");
        // Se usará currentUser.displayName o el fallback "Usuario"
      }

      if (nombreFirestore.isNotEmpty) {
        inicial = nombreFirestore.substring(0, 1).toUpperCase();
      } else if (email.isNotEmpty) {
        inicial = email.substring(0, 1).toUpperCase();
      }
      
      if (mounted) {
        setState(() {
          _nombreUsuario = nombreFirestore;
          _emailUsuario = email;
          _inicialUsuario = inicial;
        });
      }

    } else {
      // No hay usuario logueado, mantener valores por defecto
       if (mounted) {
        setState(() {
          _nombreUsuario = "Usuario";
          _emailUsuario = "email@example.com";
          _inicialUsuario = "?";
        });
      }
    }
    if (mounted) {
      setState(() {
        _cargandoDatos = false;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Paginalogin()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      print("Error signing out: $e");
      if (!mounted) return;
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
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ListTile(
                  leading: CircleAvatar(
                     backgroundColor: colorScheme.primaryContainer,
                     foregroundColor: colorScheme.onPrimaryContainer,
                     child: _cargandoDatos
                        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimaryContainer))
                        : Text(_inicialUsuario),
                  ),
                  title: _cargandoDatos
                      ? Text("Cargando...", style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant))
                      : Text(
                          _nombreUsuario,
                          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                  subtitle: _cargandoDatos
                      ? Text("...", style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant))
                      : Text(
                          _emailUsuario,
                          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                  trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: colorScheme.onSurfaceVariant),
                  onTap: _cargandoDatos ? null : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Editarusuario()),
                    ).then((_) => _cargarDatosUsuario()); // Recargar datos al volver
                  },
                ),
              ),
            ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),

            const SizedBox(height: 24),

            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                   _buildSettingsTile(
                     context: context,
                     icon: Icons.person_outline_rounded,
                     title: 'Editar Perfil',
                     onTap: _cargandoDatos ? null : () {
                       Navigator.push(
                         context,
                         MaterialPageRoute(builder: (context) => const Editarusuario()),
                       ).then((_) => _cargarDatosUsuario()); // Recargar datos al volver
                     },
                   ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: () => _logout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.errorContainer,
                foregroundColor: colorScheme.onErrorContainer,
                minimumSize: const Size(double.infinity, 50),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Cerrar Sesión'),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
     required BuildContext context,
     required IconData icon,
     required String title,
     required VoidCallback? onTap, // Cambiado a VoidCallback? para permitir null
  }) {
     final colorScheme = Theme.of(context).colorScheme;
     final textTheme = Theme.of(context).textTheme;

     return ListTile(
       contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
       leading: Icon(icon, color: onTap == null ? colorScheme.onSurface.withOpacity(0.38) : colorScheme.primary),
       title: Text(
         title,
         style: textTheme.titleMedium?.copyWith(
           color: onTap == null ? colorScheme.onSurface.withOpacity(0.38) : null
         ),
       ),
       trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: onTap == null ? colorScheme.onSurfaceVariant.withOpacity(0.38) : colorScheme.onSurfaceVariant),
       onTap: onTap,
     );
  }
}