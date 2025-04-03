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
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _showCurrentPassword = false;
  
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
    
    // Si quiere cambiar la contraseña pero no proporciona la actual
    if (_passwordController.text.isNotEmpty && _currentPasswordController.text.isEmpty) {
      setState(() {
        _showCurrentPassword = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introduce tu contraseña actual para confirmar cambios')),
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
      
      // 1. Primero actualizar Firestore (operación menos sensible)
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(currentUser.uid)
          .update({
            'nombre': _nombreController.text,
          });
      
      // 2. Actualizar nombre de usuario en Auth
      await currentUser.updateDisplayName(_nombreController.text);
      
      // 3. Si hay cambio de contraseña, reautenticar y cambiarla
      if (_passwordController.text.isNotEmpty && _passwordController.text.length >= 6) {
        // Reautenticar usuario con su contraseña actual
        final credential = EmailAuthProvider.credential(
          email: currentUser.email!, 
          password: _currentPasswordController.text
        );
        
        await currentUser.reauthenticateWithCredential(credential);
        await currentUser.updatePassword(_passwordController.text);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Datos actualizados correctamente!')),
      );
      
      Navigator.pop(context);
    } catch (e) {
      String errorMsg = 'Error al actualizar datos';
      
      // Mensajes de error más específicos
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'wrong-password':
            errorMsg = 'La contraseña actual es incorrecta';
            break;
          case 'requires-recent-login':
            errorMsg = 'Por seguridad, inicia sesión nuevamente y vuelve a intentarlo';
            break;
          case 'weak-password':
            errorMsg = 'La contraseña debe tener al menos 6 caracteres';
            break;
          default:
            errorMsg = 'Error de autenticación: ${e.message}';
        }
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
                                
                                // Campo para nueva contraseña
                                TextField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    labelText: 'Nueva contraseña (opcional)',
                                    labelStyle: const TextStyle(color: Colors.black),
                                    prefixIcon: const Icon(
                                      Icons.lock,
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
                                    helperText: 'Mínimo 6 caracteres',
                                  ),
                                  onChanged: (value) {
                                    // Mostrar campo de contraseña actual si comienza a escribir
                                    if (value.isNotEmpty && !_showCurrentPassword) {
                                      setState(() {
                                        _showCurrentPassword = true;
                                      });
                                    }
                                  },
                                ),
                                if (_showCurrentPassword) ...[
                                  const SizedBox(height: 15),
                                  // Campo para contraseña actual (requerido para cambios sensibles)
                                  TextField(
                                    controller: _currentPasswordController,
                                    obscureText: true,
                                    decoration: InputDecoration(
                                      labelText: 'Contraseña actual',
                                      labelStyle: const TextStyle(color: Colors.black),
                                      prefixIcon: const Icon(
                                        Icons.key,
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
                                ],
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
    _passwordController.dispose();
    _currentPasswordController.dispose();
    super.dispose();
  }
}