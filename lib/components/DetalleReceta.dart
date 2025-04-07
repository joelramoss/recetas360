import 'package:flutter/material.dart';
import 'package:recetas360/components/Receta.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recetas360/serveis/UsuarioUtil.dart';
import 'Receta.dart';
import 'nutritionalifno.dart';
import 'package:recetas360/components/PasosRecetaScreen.dart';

class DetalleReceta extends StatefulWidget {
  final Receta receta;

  const DetalleReceta({Key? key, required this.receta}) : super(key: key);

  @override
  _DetalleRecetaState createState() => _DetalleRecetaState();
}

class _DetalleRecetaState extends State<DetalleReceta> {
  final TextEditingController _comentarioController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final UsuarioUtil _usuarioUtil = UsuarioUtil();
  
  // Variables para lazy loading
  final int _comentariosPorPagina = 10;
  List<DocumentSnapshot> _comentarios = [];
  DocumentSnapshot? _ultimoComentario;
  bool _cargandoMas = false;
  bool _todosCargados = false;
  bool _cargaInicial = true;
  
  @override
  void initState() {
    super.initState();
    _cargarComentariosIniciales();
    
    // Listener para detectar cuando se llega al final de la lista
    _scrollController.addListener(_scrollListener);
  }
  
  void _scrollListener() {
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent - 200 &&
        !_scrollController.position.outOfRange &&
        !_cargandoMas &&
        !_todosCargados) {
      _cargarMasComentarios();
    }
  }

  Future<void> _cargarComentariosIniciales() async {
    try {
      setState(() {
        _cargaInicial = true;
      });
      
      final snapshot = await FirebaseFirestore.instance
          .collection('recetas')
          .doc(widget.receta.id)
          .collection('comentarios')
          .orderBy('fecha', descending: true)
          .limit(_comentariosPorPagina)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _comentarios = snapshot.docs;
          _ultimoComentario = snapshot.docs.last;
          _todosCargados = snapshot.docs.length < _comentariosPorPagina;
        });
      } else {
        setState(() {
          _todosCargados = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar comentarios: $e')),
      );
    } finally {
      setState(() {
        _cargaInicial = false;
      });
    }
  }
  
  Future<void> _cargarMasComentarios() async {
    if (_todosCargados || _cargandoMas) return;
    
    try {
      setState(() {
        _cargandoMas = true;
      });
      
      final snapshot = await FirebaseFirestore.instance
          .collection('recetas')
          .doc(widget.receta.id)
          .collection('comentarios')
          .orderBy('fecha', descending: true)
          .startAfterDocument(_ultimoComentario!)
          .limit(_comentariosPorPagina)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _comentarios.addAll(snapshot.docs);
          _ultimoComentario = snapshot.docs.last;
          _todosCargados = snapshot.docs.length < _comentariosPorPagina;
        });
      } else {
        setState(() {
          _todosCargados = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar más comentarios: $e')),
      );
    } finally {
      setState(() {
        _cargandoMas = false;
      });
    }
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _agregarComentario(String comentario) async {
    try {
      String? idUsuarioActual = UsuarioUtil().getUidUsuarioActual();
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(idUsuarioActual)
          .get();
      String nombreUsuario = userDoc.get('nombre') ?? 'Usuario desconocido';

      // Crear el objeto de comentario para mantener consistencia
      Map<String, dynamic> nuevoComentarioData = {
        'comentario': comentario,
        'usuarioId': idUsuarioActual,
        'usuarioNombre': nombreUsuario,
        'fecha': FieldValue.serverTimestamp(),
      };

      // Añadir comentario a Firestore
      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('recetas')
          .doc(widget.receta.id)
          .collection('comentarios')
          .add(nuevoComentarioData);
      
      // Obtener el documento recién creado
      DocumentSnapshot newComment = await docRef.get();
      
      setState(() {
        // Insertar al inicio de la lista de comentarios
        _comentarios.insert(0, newComment);
      });
      
      // Animación de scroll suave hacia arriba para ver el comentario recién añadido
      if (_scrollController.hasClients && _comentarios.length > 1) {
        await Future.delayed(const Duration(milliseconds: 100));
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutQuint,
        );
      }
      
      _comentarioController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comentario agregado')),
      );
    } catch (e) {
      print('Error al agregar comentario: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al agregar comentario: ${e.toString()}')),
      );
    }
  }

  Future<void> _agregarRespuesta(String comentarioPadreId, String respuesta) async {
    try {
      String? idUsuarioActual = UsuarioUtil().getUidUsuarioActual();
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(idUsuarioActual)
          .get();
      String nombreUsuario = userDoc.get('nombre') ?? 'Usuario desconocido';

      // Crear el objeto de respuesta
      Map<String, dynamic> nuevaRespuestaData = {
        'comentario': respuesta,
        'usuarioId': idUsuarioActual,
        'usuarioNombre': nombreUsuario,
        'fecha': FieldValue.serverTimestamp(),
        'esRespuesta': true,
        'comentarioPadreId': comentarioPadreId,
      };

      // Añadir respuesta a Firestore
      await FirebaseFirestore.instance
          .collection('recetas')
          .doc(widget.receta.id)
          .collection('comentarios')
          .add(nuevaRespuestaData);
      
      // Mostrar mensaje de confirmación
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Respuesta agregada')),
      );
      
      // Recargamos los comentarios FUERA del setState
      await _cargarComentariosIniciales();
      
    } catch (e) {
      print('Error al agregar respuesta: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al agregar respuesta: ${e.toString()}')),
      );
    }
  }

  void _mostrarDialogoRespuesta(String comentarioId, String nombreUsuario) {
    final TextEditingController respuestaController = TextEditingController();
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Responder",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => Container(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutQuad,
        );
        
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
            child: AlertDialog(
              title: Text('Responder a ${nombreUsuario}'),
              content: TextField(
                controller: respuestaController,
                decoration: const InputDecoration(
                  hintText: 'Escribe tu respuesta...',
                ),
                maxLines: 3,
                autofocus: true,
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: TextButton(
                    onPressed: () async {
                      if (respuestaController.text.trim().isNotEmpty) {
                        await _agregarRespuesta(comentarioId, respuestaController.text.trim());
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('Responder', style: TextStyle(color: Colors.orangeAccent)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) => respuestaController.dispose());
  }

  List<Widget> _buildComentariosAgrupados() {
    // Agrupar respuestas con sus comentarios padre
    Map<String, List<DocumentSnapshot>> respuestasPorComentario = {};
    List<DocumentSnapshot> comentariosPrincipales = [];
    
    // Primero clasifica comentarios y respuestas
    for (var doc in _comentarios) {
      final data = doc.data() as Map<String, dynamic>;
      final esRespuesta = data['esRespuesta'] == true;
      
      if (esRespuesta && data['comentarioPadreId'] != null) {
        final parentId = data['comentarioPadreId'] as String;
        respuestasPorComentario.putIfAbsent(parentId, () => []).add(doc);
      } else {
        comentariosPrincipales.add(doc);
      }
    }
    
    List<Widget> comentariosWidgets = [];
    String? ultimoUsuarioId;
    bool hayRespuestasIntermediasDesdeUltimoComentario = false;
    
    for (int i = 0; i < comentariosPrincipales.length; i++) {
      final doc = comentariosPrincipales[i];
      final comentario = doc.data() as Map<String, dynamic>;
      final usuarioId = comentario['usuarioId'] as String?;
      final fecha = comentario['fecha'] != null
          ? (comentario['fecha'] as Timestamp).toDate()
          : DateTime.now();
      final esUsuarioActual = usuarioId == _usuarioUtil.getUidUsuarioActual();
      
      // Determinar si mostrar el encabezado del usuario
      final bool mostrarEncabezado = usuarioId != ultimoUsuarioId || hayRespuestasIntermediasDesdeUltimoComentario;
      
      // Construir el widget del comentario
      comentariosWidgets.add(
        Column(
          children: [
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: esUsuarioActual ? Colors.orange[50] : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Solo mostrar el encabezado si es necesario
                    if (mostrarEncabezado)
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.orangeAccent,
                            child: Text(
                              (comentario['usuarioNombre'] != null && 
                              comentario['usuarioNombre'].toString().isNotEmpty)
                                ? comentario['usuarioNombre'].toString()[0].toUpperCase()
                                : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            comentario['usuarioNombre'] ?? 'Usuario desconocido',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (esUsuarioActual) ...[
                            const SizedBox(width: 8),
                            const Text(
                              '(Tú)',
                              style: TextStyle(
                                color: Colors.orangeAccent,
                                fontStyle: FontStyle.italic
                              ),
                            ),
                          ],
                        ],
                      ),
                    
                    if (mostrarEncabezado) const SizedBox(height: 8),
                    
                    // Contenido del comentario
                    Text(comentario['comentario'] ?? 'Sin comentario'),
                    
                    const SizedBox(height: 8),
                    
                    // Fecha y botón de responder
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatearFecha(fecha),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            _mostrarDialogoRespuesta(doc.id, comentario['usuarioNombre'] ?? 'Usuario');
                          },
                          icon: const Icon(Icons.reply, size: 16, color: Colors.orangeAccent),
                          label: const Text(
                            'Responder',
                            style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Si hay respuestas para este comentario, mostrarlas
            if (respuestasPorComentario.containsKey(doc.id))
              Padding(
                padding: const EdgeInsets.only(left: 24.0),
                child: Column(
                  children: [
                    // Línea conectora
                    Container(
                      height: 15,
                      width: 2,
                      margin: const EdgeInsets.only(left: 14),
                      color: Colors.grey[300],
                    ),
                    ...respuestasPorComentario[doc.id]!.map((respuestaDoc) {
                      final respuestaData = respuestaDoc.data() as Map<String, dynamic>;
                      final fechaRespuesta = respuestaData['fecha'] != null
                          ? (respuestaData['fecha'] as Timestamp).toDate()
                          : DateTime.now();
                      final esUsuarioActualRespuesta = 
                          respuestaData['usuarioId'] == _usuarioUtil.getUidUsuarioActual();
                      
                      return Stack(
                        children: [
                          // Línea horizontal conectora
                          Positioned(
                            left: -10,
                            top: 20,
                            child: Container(
                              width: 24,
                              height: 2,
                              color: Colors.grey[300],
                            ),
                          ),
                          Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: esUsuarioActualRespuesta ? Colors.orange[50] : Colors.grey[50],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey[200]!),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor: esUsuarioActualRespuesta 
                                            ? Colors.orangeAccent
                                            : Colors.grey,
                                        child: Text(
                                          (respuestaData['usuarioNombre'] != null)
                                            ? respuestaData['usuarioNombre'].toString()[0].toUpperCase()
                                            : 'U',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        respuestaData['usuarioNombre'] ?? 'Usuario desconocido',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      if (esUsuarioActualRespuesta) ...[
                                        const SizedBox(width: 8),
                                        const Text(
                                          '(Tú)',
                                          style: TextStyle(
                                            color: Colors.orangeAccent,
                                            fontStyle: FontStyle.italic,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 4),
                                  
                                  // Etiqueta de "En respuesta a"
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.reply,
                                          size: 12,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "Respuesta a ${comentario['usuarioNombre']}",
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 8),
                                  Text(respuestaData['comentario'] ?? 'Sin respuesta'),
                                  
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      _formatearFecha(fechaRespuesta),
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
          ],
        ),
      );
      
      // Actualizar el último usuario para la siguiente iteración
      ultimoUsuarioId = usuarioId;
      
      // Verificar si este comentario tiene respuestas que romperán la continuidad
      hayRespuestasIntermediasDesdeUltimoComentario = respuestasPorComentario.containsKey(doc.id);
    }
    
    return comentariosWidgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receta.nombre),
        backgroundColor: Colors.orangeAccent,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen de la receta
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.receta.urlImagen,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 50),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Información básica
            Row(
              children: [
                const Icon(Icons.timer, color: Colors.orangeAccent),
                const SizedBox(width: 8),
                Text("${widget.receta.tiempoMinutos} min"),
              ],
            ),

            const Divider(height: 32),

            // Ingredientes
            const Text(
              "Ingredientes:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...widget.receta.ingredientes.map((ing) {
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(ing),
              );
            }).toList(),

            const Divider(height: 32),

            // Descripción
            const Text(
              "Descripción:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(widget.receta.descripcion),

            const SizedBox(height: 24),
            
            // Botón Iniciar (colocado antes de los comentarios)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PasosRecetaScreen(receta: widget.receta),
                  ),
                );
              },
              child: const Text(
                "Iniciar",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            const Divider(height: 32),

            // SECCIÓN DE COMENTARIOS MEJORADA
            const Text(
              "Comentarios:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Formulario para nuevo comentario rediseñado
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Campo de texto que se expande automáticamente
                  Expanded(
                    child: TextField(
                      controller: _comentarioController,
                      maxLines: 4, // Permite hasta 4 líneas
                      minLines: 1, // Comienza con 1 línea
                      textInputAction: TextInputAction.newline, // Permite salto de línea
                      decoration: const InputDecoration(
                        hintText: "Escribe un comentario...",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  // Botón de enviar más pequeño
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(50),
                      onTap: () {
                        final comentarioTexto = _comentarioController.text.trim();
                        if (comentarioTexto.isNotEmpty) {
                          _agregarComentario(comentarioTexto);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('El comentario no puede estar vacío'),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _comentarioController.text.trim().isEmpty 
                              ? Colors.grey.withOpacity(0.7) 
                              : Colors.orangeAccent,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 20,
                            key: ValueKey<bool>(_comentarioController.text.trim().isNotEmpty),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Sección de comentarios con lazy loading
            _cargaInicial 
            ? const Center(child: CircularProgressIndicator())
            : _comentarios.isEmpty 
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No hay comentarios aún. ¡Sé el primero en comentar!',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                )
              : Column(
                  children: [
                    ..._buildComentariosAgrupados().asMap().entries.map((entry) {
                      final index = entry.key;
                      final widget = entry.value;
                      
                      // Añade animación de aparición con retraso según la posición
                      return AnimatedOpacity(
                        opacity: 1.0,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                        // Retraso basado en la posición para efecto cascada
                        child: AnimatedSlide(
                          offset: Offset.zero,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutQuint,
                          child: widget,
                        ),
                      );
                    }).toList(),
                    
                    // Indicador de carga para más comentarios
                    if (_cargandoMas)
                      AnimatedOpacity(
                        opacity: 1.0,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeIn,
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _comentarioController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
}