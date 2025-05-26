import 'package:flutter/material.dart';
import 'package:recetas360/components/Receta.dart'; // Ensure path is correct
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recetas360/serveis/UsuarioUtil.dart'; // Ensure path is correct
import 'package:recetas360/components/PasosRecetaScreen.dart'; // Ensure path is correct
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Necessary for date formatting
import 'package:flutter_animate/flutter_animate.dart'; // Import flutter_animate
import 'package:shimmer/shimmer.dart'; // Import shimmer for comment loading
import 'package:intl/date_symbol_data_local.dart'; // Necesario para initializeDateFormatting

// Current User's Login: joelramoss
// Current Date and Time (UTC - YYYY-MM-DD HH:MM:SS formatted): 2025-04-24 15:04:29

class DetalleReceta extends StatefulWidget {
  final Receta receta;

  const DetalleReceta({super.key, required this.receta});

  @override
  _DetalleRecetaState createState() => _DetalleRecetaState();
}

class _DetalleRecetaState extends State<DetalleReceta> {
  final TextEditingController _comentarioController = TextEditingController();
  Map<String, bool> _ingredientesFaltantes = {};
  Map<String, bool> _ingredientesSeleccionados = {};
  final ScrollController _scrollController = ScrollController();
  final UsuarioUtil _usuarioUtil = UsuarioUtil();

  // --- State Variables ---
  final int _comentariosPorPagina = 10;
  List<DocumentSnapshot> _comentarios = [];
  DocumentSnapshot? _ultimoComentario;
  bool _cargandoMas = false;
  bool _todosCargados = false;
  bool _cargaInicial = true;
  String? _uidActual;

  @override
  void initState() {
    super.initState();
    _initializeDateFormatting(); // Llama a la inicialización aquí
    _uidActual = _usuarioUtil.getUidUsuarioActual();
    _cargarIngredientesFaltantes(); 
    _cargarComentariosIniciales();
    _scrollController.addListener(_scrollListener);
  }

  // Nuevo método para encapsular la inicialización
  Future<void> _initializeDateFormatting() async {
    try {
      // Inicializa para el locale 'es_ES'.
      // El segundo parámetro `null` significa que usará los datos de formato por defecto para ese locale.
      await initializeDateFormatting('es_ES', null);
      print("Formato de fecha inicializado para 'es_ES'.");
      // Si quieres soportar múltiples locales o el locale por defecto del sistema de forma más robusta,
      // podrías necesitar una lógica más avanzada aquí o llamar a initializeDateFormatting
      // para el locale detectado del dispositivo.
    } catch (e) {
      print("Error al inicializar el formato de fecha para 'es_ES': $e");
      // Considera si necesitas manejar este error de alguna manera específica.
      // Incluso si esto falla, el DateFormat sin locale en tu fallback debería funcionar
      // con el formato por defecto del sistema, pero la conversión .toLocal() sigue siendo la clave.
    }
  }

  Future<void> _cargarIngredientesFaltantes() async {
    String? userId = _usuarioUtil.getUidUsuarioActual();
    if (userId != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .collection('recetas_faltantes')
          .doc(widget.receta.id)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        final faltantes = Map<String, bool>.from(data['ingredientes'] ?? {});
        if (mounted) {
          setState(() {
            _ingredientesFaltantes = faltantes;
            // Sincroniza los checkboxes con lo que hay en Firestore
            for (var ing in widget.receta.ingredientes) {
              _ingredientesSeleccionados[ing] = faltantes[ing] ?? false;
            }
          });
        }
      } else {
        // Initialize if no document exists
        if (mounted) {
          setState(() {
            _ingredientesFaltantes = {};
            for (var ing in widget.receta.ingredientes) {
              _ingredientesSeleccionados[ing] = false;
            }
          });
        }
      }
    } else {
      // Initialize for logged-out user or if userId is null
      if (mounted) {
        setState(() {
          _ingredientesFaltantes = {};
          for (var ing in widget.receta.ingredientes) {
            _ingredientesSeleccionados[ing] = false;
          }
        });
      }
    }
  }

  Future<void> _guardarIngredientesFaltantes() async {
    String? userId = _usuarioUtil.getUidUsuarioActual();
    if (userId != null) {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .collection('recetas_faltantes')
          .doc(widget.receta.id)
          .set({
        'ingredientes': _ingredientesFaltantes,
        'recetaNombre': widget.receta.nombre,
        // Optionally add a timestamp for when it was last updated
        'actualizadoEn': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // Use merge true to be safe
    }
  }

  void _marcarTodos(bool marcar) {
    setState(() {
      for (var ing in widget.receta.ingredientes) {
        _ingredientesSeleccionados[ing] = marcar;
        _ingredientesFaltantes[ing] = marcar; // Keep this for _guardarIngredientesFaltantes
      }
    });
    // First, save the complete map reflecting all true/false states
    _guardarIngredientesFaltantes();
    // Then, ensure individual items are correctly set or deleted in the carrito
    // This loop is important if 'false' means FieldValue.delete() for _actualizarCarrito
    for (var ing in widget.receta.ingredientes) {
      _actualizarCarrito(ing, marcar);
    }
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  CollectionReference get _comentariosCollectionRef => FirebaseFirestore.instance
      .collection('recetas')
      .doc(widget.receta.id)
      .collection('comentarios');

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_cargandoMas &&
        !_todosCargados) {
      _cargarMasComentarios();
    }
  }

  Future<void> _cargarComentariosIniciales() async {
    if (!mounted) return;
    setState(() {
      _cargaInicial = true; _comentarios = []; _ultimoComentario = null; _todosCargados = false; _cargandoMas = false;
    });
    try {
      final snapshot = await _comentariosCollectionRef.orderBy('fecha', descending: true).limit(_comentariosPorPagina).get();
      if (!mounted) return;
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _comentarios = snapshot.docs; _ultimoComentario = snapshot.docs.last; _todosCargados = snapshot.docs.length < _comentariosPorPagina;
        });
      } else {
        setState(() { _todosCargados = true; });
      }
    } catch (e) {
      if (!mounted) return; print("Error cargando comentarios: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar comentarios: ${e.toString()}', style: TextStyle(color: Theme.of(context).colorScheme.onError)), backgroundColor: Theme.of(context).colorScheme.error));
    } finally {
      if (!mounted) return; setState(() { _cargaInicial = false; });
    }
  }

  Future<void> _cargarMasComentarios() async {
    if (_todosCargados || _cargandoMas || _ultimoComentario == null || !mounted) return;
    setState(() { _cargandoMas = true; });
    try {
      final snapshot = await _comentariosCollectionRef.orderBy('fecha', descending: true).startAfterDocument(_ultimoComentario!).limit(_comentariosPorPagina).get();
      if (!mounted) return;
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _comentarios.addAll(snapshot.docs); _ultimoComentario = snapshot.docs.last; _todosCargados = snapshot.docs.length < _comentariosPorPagina;
        });
      } else {
        setState(() { _todosCargados = true; });
      }
    } catch (e) {
      if (!mounted) return; print("Error cargando más comentarios: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar más comentarios: ${e.toString()}', style: TextStyle(color: Theme.of(context).colorScheme.onError)), backgroundColor: Theme.of(context).colorScheme.error));
    } finally {
      if (!mounted) return; setState(() { _cargandoMas = false; });
    }
  }

  String _formatearFecha(DateTime fecha) {
    try {
      // Imprime la fecha original UTC para depuración
      print("Fecha Original (UTC desde Firestore): ${fecha.toIso8601String()}");

      // Sumar 2 horas directamente a la fecha UTC
      final fechaConDosHorasMas = fecha.add(const Duration(hours: 2));
      print("Fecha con 2 horas sumadas: ${fechaConDosHorasMas.toIso8601String()}");
      
      // Formatear esta nueva fecha. Ya no se llama a .toLocal()
      return DateFormat('dd/MM/yyyy HH:mm', 'es_ES').format(fechaConDosHorasMas);
    } catch (e) {
       print("Error formateando fecha con intl locale 'es_ES': $e. Usando formato simple.");
       // Fallback, también sumando 2 horas
       final fechaConDosHorasMasFallback = fecha.add(const Duration(hours: 2));
       return DateFormat('dd/MM/yyyy HH:mm').format(fechaConDosHorasMasFallback);
    }
  }

  Future<void> _agregarComentario(String comentarioTexto) async {
    if (_uidActual == null || !mounted) return;
    final colorScheme = Theme.of(context).colorScheme;
    try {
      String nombreUsuario = await _usuarioUtil.getNombreUsuarioActual() ?? 'Usuario';
      if (!mounted) return;

      Map<String, dynamic> nuevoComentarioData = {
        'comentario': comentarioTexto, 'usuarioId': _uidActual, 'usuarioNombre': nombreUsuario,
        'fecha': FieldValue.serverTimestamp(), 'esRespuesta': false, 'comentarioPadreId': null,
      };
      await _comentariosCollectionRef.add(nuevoComentarioData);
      if (!mounted) return;

      _comentarioController.clear();
      FocusScope.of(context).unfocus();
      _cargarComentariosIniciales(); 

      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted && _scrollController.hasClients) {
         _scrollController.animateTo(0.0, duration: const Duration(milliseconds: 500), curve: Curves.easeOutQuint);
      }
    } catch (e) {
      print('Error al agregar comentario: $e'); if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al agregar comentario: ${e.toString()}', style: TextStyle(color: colorScheme.onError)), backgroundColor: colorScheme.error));
    }
  }

  Future<void> _agregarRespuesta(String comentarioPadreId, String respuestaTexto) async {
    if (_uidActual == null || !mounted) return;
    final colorScheme = Theme.of(context).colorScheme;
    try {
       String nombreUsuario = await _usuarioUtil.getNombreUsuarioActual() ?? 'Usuario';
       if (!mounted) return;

       Map<String, dynamic> nuevaRespuestaData = {
        'comentario': respuestaTexto, 'usuarioId': _uidActual, 'usuarioNombre': nombreUsuario,
        'fecha': FieldValue.serverTimestamp(), 'esRespuesta': true, 'comentarioPadreId': comentarioPadreId,
       };
       await _comentariosCollectionRef.add(nuevaRespuestaData);
       if (!mounted) return;
       _cargarComentariosIniciales();
    } catch (e) {
      print('Error al agregar respuesta: $e'); if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al agregar respuesta: ${e.toString()}', style: TextStyle(color: colorScheme.onError)), backgroundColor: colorScheme.error));
    }
  }

  Future<void> _actualizarCarrito(String ingrediente, bool seleccionado) async {
    String? userId = _usuarioUtil.getUidUsuarioActual();
    if (userId == null) return;
    final docRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .collection('recetas_faltantes') // This collection stores what's missing for a recipe
        .doc(widget.receta.id);

    bool esFaltante = _ingredientesFaltantes[ingrediente] ?? false;

    if (esFaltante) {
      await docRef.set({
        'ingredientes.$ingrediente': true,
        'recetaNombre': widget.receta.nombre,
        'actualizadoEn': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      await docRef.update({
        'ingredientes.$ingrediente': FieldValue.delete(),
      });
    }
  }
  
  Future<void> _borrarComentario(String comentarioId) async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Confirmar Borrado'),
        content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );

    if (!mounted || confirmar != true) return;

    try {
      await _comentariosCollectionRef.doc(comentarioId).delete();
      if (!mounted) return;
      setState(() { _comentarios.removeWhere((doc) => doc.id == comentarioId); });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comentario borrado')));
    } catch (e) {
      print("Error al borrar comentario: $e"); if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al borrar: ${e.toString()}', style: TextStyle(color: colorScheme.onError)), backgroundColor: colorScheme.error));
    }
  }

  void _mostrarDialogoRespuesta(String comentarioId, String nombreUsuario) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => _DialogoRespuestaWidget(
        comentarioPadreId: comentarioId,
        nombreUsuarioPadre: nombreUsuario,
        onResponder: (respuestaTexto) async => await _agregarRespuesta(comentarioId, respuestaTexto),
      ),
      transitionBuilder: (ctx, anim1, anim2, child) {
         final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutQuad);
         return ScaleTransition(
           scale: Tween<double>(begin: 0.9, end: 1.0).animate(curved),
           child: FadeTransition(opacity: anim1, child: child),
         );
      },
    );
  }

  List<Widget> _buildComentariosAgrupados(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Map<String, List<DocumentSnapshot>> respuestasPorComentario = {};
    List<DocumentSnapshot> comentariosPrincipales = [];
    for (var doc in _comentarios) {
      final data = doc.data() as Map<String, dynamic>?; if (data == null) continue;
      final bool esRespuesta = data['esRespuesta'] == true;
      final String? comentarioPadreId = data['comentarioPadreId'] as String?;
      if (esRespuesta && comentarioPadreId != null) {
        respuestasPorComentario.putIfAbsent(comentarioPadreId, () => []).add(doc);
      } else if (!esRespuesta) {
        comentariosPrincipales.add(doc);
      }
    }
    respuestasPorComentario.forEach((key, listaRespuestas) {
      listaRespuestas.sort((a, b) {
        final fechaA = (a.data() as Map<String, dynamic>?)?['fecha'] as Timestamp?;
        final fechaB = (b.data() as Map<String, dynamic>?)?['fecha'] as Timestamp?;
        if (fechaA == null && fechaB == null) return 0;
        if (fechaA == null) return -1;
        if (fechaB == null) return 1;
        return fechaA.compareTo(fechaB);
      });
    });

    List<Widget> comentariosWidgets = [];
    for (int i = 0; i < comentariosPrincipales.length; i++) {
      final doc = comentariosPrincipales[i];
      final comentarioData = doc.data() as Map<String, dynamic>?; if (comentarioData == null) continue;

      final usuarioId = comentarioData['usuarioId'] as String?;
      final fecha = comentarioData['fecha'] != null ? (comentarioData['fecha'] as Timestamp).toDate() : DateTime.now();
      final esUsuarioActual = _uidActual != null && usuarioId == _uidActual;
      final nombreUsuario = comentarioData['usuarioNombre'] ?? 'Usuario';
      final comentarioTexto = comentarioData['comentario'] ?? '';

      comentariosWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Card(
            elevation: esUsuarioActual ? 0 : 1,
            color: esUsuarioActual ? colorScheme.primaryContainer.withOpacity(0.4) : colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                     crossAxisAlignment: CrossAxisAlignment.center,
                     children: [
                       CircleAvatar(
                         radius: 16,
                         backgroundColor: colorScheme.primary,
                         child: Text(
                           nombreUsuario.isNotEmpty ? nombreUsuario[0].toUpperCase() : '?',
                           style: textTheme.labelMedium?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
                         ),
                       ),
                       const SizedBox(width: 10),
                       Expanded(child: Text(nombreUsuario, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                       if (esUsuarioActual) Padding(padding: const EdgeInsets.only(left: 8.0), child: Text('(Tú)', style: textTheme.labelMedium?.copyWith(color: colorScheme.primary, fontStyle: FontStyle.italic))),
                       if (esUsuarioActual) IconButton(
                         icon: Icon(Icons.delete_outline_rounded, color: colorScheme.error, size: 20),
                         padding: EdgeInsets.zero, visualDensity: VisualDensity.compact,
                         tooltip: 'Borrar',
                         onPressed: () => _borrarComentario(doc.id),
                       ),
                     ],
                   ),
                  const SizedBox(height: 8),
                  Text(comentarioTexto, style: textTheme.bodyMedium),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatearFecha(fecha), style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                      TextButton.icon(
                        onPressed: () => _mostrarDialogoRespuesta(doc.id, nombreUsuario),
                        icon: Icon(Icons.reply_rounded, size: 16, color: colorScheme.primary),
                        label: Text('Responder', style: textTheme.labelMedium?.copyWith(color: colorScheme.primary)),
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        )
        .animate().fadeIn(duration: 400.ms, delay: (50 * i).ms).slideY(begin: 0.1, curve: Curves.easeOutCubic)
      );

      if (respuestasPorComentario.containsKey(doc.id)) {
        comentariosWidgets.add(
          Padding(
             padding: const EdgeInsets.only(left: 32.0, top: 0, bottom: 4, right: 0),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: respuestasPorComentario[doc.id]!.asMap().entries.map((entry) {
                 int replyIndex = entry.key; DocumentSnapshot respuestaDoc = entry.value;
                 final respuestaData = respuestaDoc.data() as Map<String, dynamic>?; if (respuestaData == null) return const SizedBox.shrink();

                 final fechaRespuesta = respuestaData['fecha'] != null ? (respuestaData['fecha'] as Timestamp).toDate() : DateTime.now();
                 final esUsuarioActualRespuesta = _uidActual != null && respuestaData['usuarioId'] == _uidActual;
                 final nombreUsuarioRespuesta = respuestaData['usuarioNombre'] ?? 'Usuario';
                 final respuestaTexto = respuestaData['comentario'] ?? '';

                 return Padding(
                   padding: const EdgeInsets.only(top: 8.0),
                   child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5))),
                      color: esUsuarioActualRespuesta ? colorScheme.secondaryContainer.withOpacity(0.3) : null,
                     child: Padding(
                       padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Row(
                             crossAxisAlignment: CrossAxisAlignment.center,
                             children: [
                               CircleAvatar(radius: 12, backgroundColor: colorScheme.secondary, child: Text(nombreUsuarioRespuesta.isNotEmpty ? nombreUsuarioRespuesta[0].toUpperCase() : '?', style: textTheme.labelSmall?.copyWith(color: colorScheme.onSecondary, fontWeight: FontWeight.bold))),
                               const SizedBox(width: 8),
                               Expanded(child: Text(nombreUsuarioRespuesta, style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                               if (esUsuarioActualRespuesta) Padding(padding: const EdgeInsets.only(left: 6.0), child: Text('(Tú)', style: textTheme.labelMedium?.copyWith(color: colorScheme.secondary, fontStyle: FontStyle.italic))),
                               if (esUsuarioActualRespuesta) IconButton(icon: Icon(Icons.delete_outline_rounded, color: colorScheme.error, size: 18), padding: EdgeInsets.zero, constraints: const BoxConstraints(), visualDensity: VisualDensity.compact, tooltip: 'Borrar', onPressed: () => _borrarComentario(respuestaDoc.id)),
                             ],
                           ),
                           const SizedBox(height: 6),
                           Text(respuestaTexto, style: textTheme.bodySmall),
                           const SizedBox(height: 6),
                           Align(alignment: Alignment.centerRight, child: Text(_formatearFecha(fechaRespuesta), style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant))),
                         ],
                       ),
                     ),
                   ),
                 )
                 .animate().fadeIn(duration: 300.ms, delay: (50 * replyIndex).ms).slideX(begin: 0.1, curve: Curves.easeOut);
               }).toList(),
             ),
           ),
        );
      }
    }
    return comentariosWidgets;
  }

  Widget _buildShimmerCommentList(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final shimmerBaseColor = colorScheme.surfaceContainerHighest;
    final shimmerHighlightColor = colorScheme.surfaceContainer;

    return Shimmer.fromColors(
      baseColor: shimmerBaseColor, highlightColor: shimmerHighlightColor,
      child: Column(
        children: List.generate(3, (index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Card(
             elevation: 0,
             color: shimmerBaseColor,
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
             child: Padding(
               padding: const EdgeInsets.all(12.0),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Row(children: [ const CircleAvatar(radius: 16, backgroundColor: Colors.white), const SizedBox(width: 10), Container(height: 14, width: 100, color: Colors.white), const Spacer(), Container(height: 14, width: 50, color: Colors.white)]),
                   const SizedBox(height: 10),
                   Container(height: 12, width: double.infinity, color: Colors.white, margin: const EdgeInsets.only(bottom: 6)),
                   Container(height: 12, width: double.infinity, color: Colors.white, margin: const EdgeInsets.only(bottom: 10)),
                   Align(alignment: Alignment.centerRight, child: Container(height: 10, width: 80, color: Colors.white)),
                 ],
               ),
             ),
          ),
        )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: GestureDetector(
         onTap: () => FocusScope.of(context).unfocus(),
         child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverAppBar(
              expandedHeight: screenHeight * 0.35,
              pinned: true,
              stretch: true,
              backgroundColor: colorScheme.surface,
              foregroundColor: colorScheme.onSurface,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                title: Text(
                  widget.receta.nombre,
                ),
                centerTitle: true,
                background: Hero(
                  tag: 'recipe_image_${widget.receta.id}',
                  child: Image.network(
                     widget.receta.urlImagen, fit: BoxFit.cover,
                     loadingBuilder: (context, child, progress) => progress == null
                         ? child
                         : Shimmer.fromColors(
                             baseColor: colorScheme.surfaceContainerHighest,
                             highlightColor: colorScheme.surfaceContainer,
                             child: Container(color: Colors.white)
                           ),
                     errorBuilder: (context, error, stack) => Container(
                       color: colorScheme.surfaceContainer,
                       child: Center(child: Icon(Icons.broken_image_outlined, color: colorScheme.onSurfaceVariant, size: 50)),
                     ),
                  ),
                ),
                 stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
              ),
               actions: [ // Actions for SliverAppBar
                // IconButton(
                //   icon: const Icon(Icons.shopping_cart_outlined), // Use outlined for consistency
                //   tooltip: "Ver faltantes",
                //   onPressed: () => _mostrarIngredientesFaltantes(context),
                // ),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [ Icon(Icons.timer_outlined, color: colorScheme.primary, size: 20), const SizedBox(width: 8), Text("${widget.receta.tiempoMinutos} min", style: textTheme.titleMedium)]),
                      Row(children: List.generate(5, (i) => Icon(i < widget.receta.calificacion ? Icons.star_rounded : Icons.star_border_rounded, color: colorScheme.primary, size: 22))
                          .animate(interval: 50.ms).fadeIn(delay: 300.ms)),
                    ],
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
                  const Divider(height: 32, thickness: 1),

                  Text("Ingredientes", style: textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8.0, runSpacing: 6.0,
                    children: widget.receta.ingredientes.map((ing) => Chip(
                      label: Text(ing),
                      backgroundColor: colorScheme.secondaryContainer.withOpacity(0.7),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    )).toList()
                  ).animate().fadeIn(delay: 400.ms),
                  const Divider(height: 32, thickness: 1),

                  // --- INGREDIENTES POR COMPRAR ---
                  Text(
                    "Ingredientes por comprar:",
                    style: textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  ...widget.receta.ingredientes.map((ing) {
                    return CheckboxListTile(
                      title: Text(ing),
                      value: _ingredientesSeleccionados[ing] ?? false,
                      onChanged: (bool? value) async {
                        setState(() {
                          _ingredientesSeleccionados[ing] = value ?? false;
                          // Update _ingredientesFaltantes based on the checkbox
                          // If checked (user has it), it's NOT faltante.
                          // If unchecked (user doesn't have it), it IS faltante.
                          _ingredientesFaltantes[ing] = !(value ?? true);
                        });
                        // No need to call _guardarIngredientesFaltantes here,
                        // _actualizarCarrito will handle the specific ingredient.
                        // Or, if you prefer, call _guardarIngredientesFaltantes after all changes.
                        await _actualizarCarrito(ing, !(value ?? true));
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: colorScheme.primary,
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => _marcarTodos(false), // Marcar todos como "NO FALTANTES" (checkboxes ON)
                        child: const Text("Tengo todo"),
                      ),
                      ElevatedButton(
                        onPressed: () => _marcarTodos(true), // Marcar todos como "FALTANTES" (checkboxes OFF)
                        child: const Text("No tengo nada"),
                      ),
                    ],
                  ),
                  const Divider(height: 32, thickness: 1),
                  // --- END INGREDIENTES POR COMPRAR ---
                  
                  Text("Descripción", style: textTheme.titleLarge),
                  const SizedBox(height: 10),
                  Text(
                    widget.receta.descripcion,
                    style: textTheme.bodyLarge?.copyWith(height: 1.5),
                    textAlign: TextAlign.justify,
                  ).animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: 30),

                  Center(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14), textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PasosRecetaScreen(receta: widget.receta))),
                      icon: const Icon(Icons.play_circle_fill_rounded),
                      label: const Text("Iniciar Preparación"),
                    )
                  ).animate().fadeIn(delay: 600.ms).shake(hz: 3, duration: 400.ms),
                  const Divider(height: 40, thickness: 1),

                  Text("Comentarios", style: textTheme.titleLarge),
                  const SizedBox(height: 15),

                  Container(
                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                     decoration: BoxDecoration(
                       color: colorScheme.surfaceContainerHighest,
                       borderRadius: BorderRadius.circular(30)
                     ),
                     child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: TextField(
                            controller: _comentarioController, maxLines: null, minLines: 1, keyboardType: TextInputType.multiline, textInputAction: TextInputAction.newline,
                            style: textTheme.bodyMedium,
                            decoration: InputDecoration(
                              hintText: "Añade un comentario...",
                              hintStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            ),
                            onChanged: (_) => setState(() {}),
                          )),
                          IconButton(
                            icon: const Icon(Icons.send_rounded),
                            color: _comentarioController.text.trim().isEmpty ? colorScheme.onSurfaceVariant : colorScheme.primary,
                            visualDensity: VisualDensity.compact,
                            tooltip: "Enviar",
                            onPressed: _comentarioController.text.trim().isEmpty ? null : () { _agregarComentario(_comentarioController.text.trim()); },
                          ),
                     ]),
                  ).animate().fadeIn(delay: 700.ms),
                  const SizedBox(height: 25),

                  // --- INICIO: RefreshIndicator para comentarios ---
                  RefreshIndicator(
                    onRefresh: _cargarComentariosIniciales, // Llama a tu función de carga inicial
                    color: colorScheme.primary,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    child: _cargaInicial
                        ? _buildShimmerCommentList(context)
                        : _comentarios.isEmpty
                            ? Padding( // Envuelve el mensaje de "no hay comentarios" en un ListView para que RefreshIndicator funcione
                                padding: const EdgeInsets.symmetric(vertical: 40.0),
                                child: ListView( // Necesario para que RefreshIndicator tenga un scrollable child
                                  shrinkWrap: true, // Para que no ocupe toda la altura si no hay contenido
                                  physics: const AlwaysScrollableScrollPhysics(), // Para permitir el pull-to-refresh incluso si no hay scroll
                                  children: [
                                    Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                      Icon(Icons.chat_bubble_outline_rounded, size: 50, color: colorScheme.secondary),
                                      const SizedBox(height: 16),
                                      Text('No hay comentarios aún.\n¡Sé el primero!', style: textTheme.titleMedium?.copyWith(color: colorScheme.secondary), textAlign: TextAlign.center),
                                    ])),
                                  ]
                                ),
                              ).animate().fadeIn(delay: 200.ms)
                            : Column( // La lista de comentarios ya es un Column, que está bien dentro de RefreshIndicator si el CustomScrollView permite el scroll
                                children: [
                                  ..._buildComentariosAgrupados(context),
                                  if (_cargandoMas) const Padding(padding: EdgeInsets.symmetric(vertical: 20.0), child: Center(child: CircularProgressIndicator(strokeWidth: 2.0))),
                                  if (_todosCargados && _comentarios.isNotEmpty && !_cargandoMas)
                                     Padding(padding: const EdgeInsets.symmetric(vertical: 30.0), child: Center(child: Text("—— Fin ——", style: textTheme.labelMedium?.copyWith(color: colorScheme.outline)))).animate().fadeIn(),
                                ],
                              ),
                  ),
                  // --- FIN: RefreshIndicator para comentarios ---
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class _DialogoRespuestaWidget extends StatefulWidget {
  final String comentarioPadreId;
  final String nombreUsuarioPadre;
  final Future<void> Function(String respuestaTexto) onResponder;

  const _DialogoRespuestaWidget({
    required this.comentarioPadreId,
    required this.nombreUsuarioPadre,
    required this.onResponder,
  });

  @override
  __DialogoRespuestaWidgetState createState() => __DialogoRespuestaWidgetState();
}

class __DialogoRespuestaWidgetState extends State<_DialogoRespuestaWidget> {
  late final TextEditingController _respuestaController;
  bool _estaEnviando = false;

  @override
  void initState() {
    super.initState();
    _respuestaController = TextEditingController();
  }

  @override
  void dispose() {
    _respuestaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
     final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text('Responder a ${widget.nombreUsuarioPadre}'),
      content: TextField(
        controller: _respuestaController,
        decoration: const InputDecoration(
          hintText: 'Escribe tu respuesta...',
          border: OutlineInputBorder(),
        ),
        maxLines: null, minLines: 2,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        autofocus: true,
        onChanged: (_) => setState(() {}),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _estaEnviando ? null : () { Navigator.of(context).pop(); },
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _respuestaController.text.trim().isEmpty || _estaEnviando ? null : () async {
            final respuestaTexto = _respuestaController.text.trim();
            setState(() => _estaEnviando = true);
            try { await widget.onResponder(respuestaTexto); }
            catch (e) {
               print("Error en callback onResponder: $e");
               if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al enviar respuesta", style: TextStyle(color: colorScheme.onError)), backgroundColor: colorScheme.error));
            } finally {
               if (mounted) { setState(() => _estaEnviando = false); }
            }
            if (mounted) { Navigator.of(context).pop(); }
          },
          child: _estaEnviando
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary))
              : const Text('Responder'),
        ),
      ],
    );
  }
}