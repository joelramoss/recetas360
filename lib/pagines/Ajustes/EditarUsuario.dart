import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Editarusuario extends StatefulWidget {
  const Editarusuario({Key? key}) : super(key: key);

  @override
  _EditarusuarioState createState() => _EditarusuarioState();
}

class _EditarusuarioState extends State<Editarusuario> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Obtener el usuario actual de Firebase Auth
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Establecer el email actual
        _emailController.text = currentUser.email ?? '';
        
        // Buscar datos adicionales en Firestore
        final DocumentSnapshot userData = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(currentUser.uid)
            .get();
        
        if (userData.exists && userData.data() != null) {
          final data = userData.data() as Map<String, dynamic>;
          setState(() {
            _nombreController.text = data['nombre'] ?? '';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _updateUserData() async {
    if (_nombreController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre no puede estar vacío')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Obtener el usuario actual
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("No hay usuario autenticado");
      }
      
      // 1. Actualizar Firestore
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(currentUser.uid)
          .update({
            'nombre': _nombreController.text,
          });
      
      // 2. Actualizar nombre de usuario en Auth
      await currentUser.updateDisplayName(_nombreController.text);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Datos actualizados correctamente!')),
      );
      
      Navigator.pop(context);
    } catch (e) {
      String errorMsg = 'Error al actualizar datos';
      
      // Mensajes de error simplificados (ya que no hay cambio de contraseña)
      if (e is FirebaseAuthException) {
        errorMsg = 'Error de autenticación: ${e.message}';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orangeAccent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Editar Usuario",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orangeAccent,
              Colors.pink.shade100,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Container(
                            width: 320,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Icono de usuario
                                const CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.orangeAccent,
                                  child: Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                
                                // Campo para "Nombre"
                                TextField(
                                  controller: _nombreController,
                                  decoration: InputDecoration(
                                    labelText: 'Nombre',
                                    labelStyle: const TextStyle(color: Colors.black),
                                    prefixIcon: const Icon(
                                      Icons.person,
                                      color: Colors.black,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.black.withOpacity(0.3),
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 15),
                                
                                // Campo para "Email" (solo lectura)
                                TextField(
                                  controller: _emailController,
                                  enabled: false,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    labelStyle: TextStyle(color: Colors.grey),
                                    prefixIcon: const Icon(
                                      Icons.email,
                                      color: Colors.grey,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.black.withOpacity(0.3),
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade100,
                                  ),
                                ),
                                const SizedBox(height: 15),
                                
                                // Botón para restablecer contraseña por email
                                TextButton.icon(
                                  onPressed: () async {
                                    try {
                                      final User? user = FirebaseAuth.instance.currentUser;
                                      if (user != null) {
                                        await FirebaseAuth.instance.sendPasswordResetEmail(
                                          email: user.email!,
                                        );
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Se ha enviado un enlace de restablecimiento a tu correo'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error al enviar el correo: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.lock_reset, color: Colors.blue),
                                  label: const Text(
                                    'Restablecer contraseña por correo',
                                    style: TextStyle(color: Colors.blue),
                                  ),
                                ),
                                
                                const SizedBox(height: 20),
                                
                                // Botón de guardar cambios
                                ElevatedButton(
                                  onPressed: _updateUserData,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 40),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Guardar cambios',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
  
  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}