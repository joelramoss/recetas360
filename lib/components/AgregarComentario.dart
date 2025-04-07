// agregar_comentario.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:recetas360/serveis/UsuarioUtil.dart';

class AgregarComentario extends StatelessWidget {
  final String recetaId;
  final UsuarioUtil _usuarioUtil = UsuarioUtil(); // Instancia de la clase

  AgregarComentario({Key? key, required this.recetaId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('comentarios')
          .where('recetaId', isEqualTo: recetaId)
          .orderBy('fecha', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text("No hay comentarios aún");
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final comentario = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final comentarioId = snapshot.data!.docs[index].id;
            return Card(
              child: ListTile(
                title: Text("Usuario: ${comentario['usuarioNombre'] ?? 'Desconocido'}"),
                subtitle: Text(comentario['texto'] ?? 'Sin comentario'),
                trailing: Text(
                  comentario['fecha'] != null
                      ? DateFormat('dd/MM/yyyy').format((comentario['fecha'] as Timestamp).toDate())
                      : 'Fecha desconocida',
                ),
                onLongPress: () async {
                  final uidActual = _usuarioUtil.getUidUsuarioActual();
                  if (uidActual != null && comentario['usuarioId'] == uidActual) {
                    await _usuarioUtil.borrarComentario(comentarioId);
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}