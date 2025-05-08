import 'package:flutter/material.dart';
import 'package:recetas360/components/Receta.dart'; // Ensure path is correct
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recetas360/serveis/UsuarioUtil.dart'; // Ensure path is correct
// import 'nutritionalifno.dart'; // Uncomment if using this file and verify path
import 'package:recetas360/components/PasosRecetaScreen.dart'; // Ensure path is correct
import 'package:intl/intl.dart'; // Necessary for date formatting
import 'package:flutter_animate/flutter_animate.dart'; // Import flutter_animate
import 'package:shimmer/shimmer.dart'; // Import shimmer for comment loading

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
    _uidActual = _usuarioUtil.getUidUsuarioActual();
    // Initialize localization if using intl with localization
    // Intl.defaultLocale = 'es_ES'; // Example: Initialize locale in main.dart or here
    _cargarComentariosIniciales();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  // --- Firestore Reference ---
  CollectionReference get _comentariosCollectionRef => FirebaseFirestore.instance
      .collection('recetas')
      .doc(widget.receta.id)
      .collection('comentarios');

  // --- Scroll Listener ---
  void _scrollListener() {
    // Load more when near the bottom
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_cargandoMas &&
        !_todosCargados) {
      _cargarMasComentarios();
    }
  }

  // --- Comment Loading Logic (Keep existing robust logic) ---
  Future<void> _cargarComentariosIniciales() async {
    // Reset state for initial load
    if (!mounted) return;
    setState(() {
      _cargaInicial = true; _comentarios = []; _ultimoComentario = null; _todosCargados = false; _cargandoMas = false;
    });
    try {
      final snapshot = await _comentariosCollectionRef.orderBy('fecha', descending: true).limit(_comentariosPorPagina).get();
      if (!mounted) return; // Check mounted after await
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _comentarios = snapshot.docs; _ultimoComentario = snapshot.docs.last; _todosCargados = snapshot.docs.length < _comentariosPorPagina;
        });
      } else {
        setState(() { _todosCargados = true; });
      }
    } catch (e) {
      if (!mounted) return; print("Error cargando comentarios: $e");
      // Show themed error snackbar
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
      if (!mounted) return; // Check mounted after await
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _comentarios.addAll(snapshot.docs); _ultimoComentario = snapshot.docs.last; _todosCargados = snapshot.docs.length < _comentariosPorPagina;
        });
      } else {
        setState(() { _todosCargados = true; });
      }
    } catch (e) {
      if (!mounted) return; print("Error cargando más comentarios: $e");
      // Show themed error snackbar
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar más comentarios: ${e.toString()}', style: TextStyle(color: Theme.of(context).colorScheme.onError)), backgroundColor: Theme.of(context).colorScheme.error));
    } finally {
      if (!mounted) return; setState(() { _cargandoMas = false; });
    }
  }

  // --- Date Formatting ---
  String _formatearFecha(DateTime fecha) {
    try {
      // Ensure 'es_ES' locale is initialized if using it, otherwise use default
      return DateFormat('dd/MM/yyyy HH:mm', 'es_ES').format(fecha);
    } catch (e) {
       print("Error formateando fecha con intl locale 'es_ES': $e. Usando formato simple.");
       // Fallback format without locale
       return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
    }
  }

  // --- Add Comment/Reply/Delete Logic (Keep existing robust logic, ensure themed feedback) ---
  Future<void> _agregarComentario(String comentarioTexto) async {
    if (_uidActual == null || !mounted) return;
    final colorScheme = Theme.of(context).colorScheme;
    try {
      // Use helper method to get user name, handle potential null
      String nombreUsuario = await _usuarioUtil.getNombreUsuarioActual() ?? 'Usuario';
      if (!mounted) return; // Check again after await

      Map<String, dynamic> nuevoComentarioData = {
        'comentario': comentarioTexto, 'usuarioId': _uidActual, 'usuarioNombre': nombreUsuario,
        'fecha': FieldValue.serverTimestamp(), 'esRespuesta': false, 'comentarioPadreId': null,
      };
      await _comentariosCollectionRef.add(nuevoComentarioData);
      if (!mounted) return;

      _comentarioController.clear();
      FocusScope.of(context).unfocus(); // Hide keyboard
      _cargarComentariosIniciales(); // Reload to show the new comment at the top

      // Animate scroll to top after a short delay to allow list rebuild
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
       if (!mounted) return; // Check again after await

       Map<String, dynamic> nuevaRespuestaData = {
        'comentario': respuestaTexto, 'usuarioId': _uidActual, 'usuarioNombre': nombreUsuario,
        'fecha': FieldValue.serverTimestamp(), 'esRespuesta': true, 'comentarioPadreId': comentarioPadreId,
       };
       await _comentariosCollectionRef.add(nuevaRespuestaData);
       if (!mounted) return;
       _cargarComentariosIniciales(); // Reload to show reply in place
    } catch (e) {
      print('Error al agregar respuesta: $e'); if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al agregar respuesta: ${e.toString()}', style: TextStyle(color: colorScheme.onError)), backgroundColor: colorScheme.error));
    }
  }

   Future<void> _borrarComentario(String comentarioId) async {
       final colorScheme = Theme.of(context).colorScheme;
       // Show themed confirmation dialog
       final confirmar = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), // M3 Shape
          title: const Text('Confirmar Borrado'),
          content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: colorScheme.error), // Use theme error color for delete action
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Borrar'),
            ),
          ],
        ),
      );

      if (!mounted || confirmar != true) return; // Check mounted and confirmation

      try {
        await _comentariosCollectionRef.doc(comentarioId).delete();
        if (!mounted) return; // Check mounted after await
        setState(() { _comentarios.removeWhere((doc) => doc.id == comentarioId); }); // Update local list immediately
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comentario borrado')));
      } catch (e) {
        print("Error al borrar comentario: $e"); if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al borrar: ${e.toString()}', style: TextStyle(color: colorScheme.onError)), backgroundColor: colorScheme.error));
      }
   }

  // --- Show Reply Dialog (Keep existing logic, uses internal themed widget) ---
  void _mostrarDialogoRespuesta(String comentarioId, String nombreUsuario) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => _DialogoRespuestaWidget( // Use the themed dialog widget
        comentarioPadreId: comentarioId,
        nombreUsuarioPadre: nombreUsuario,
        onResponder: (respuestaTexto) async => await _agregarRespuesta(comentarioId, respuestaTexto),
      ),
      transitionBuilder: (ctx, anim1, anim2, child) {
         // Use curved animation for smoother transition
         final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutQuad);
         return ScaleTransition(
           scale: Tween<double>(begin: 0.9, end: 1.0).animate(curved),
           child: FadeTransition(opacity: anim1, child: child),
         );
      },
    );
  }

  // --- Build Comment List (Refactored for Theme and Animation) ---
  List<Widget> _buildComentariosAgrupados(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Grouping logic remains the same
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
    // Sort replies ascending (oldest first) within each group
    respuestasPorComentario.forEach((key, listaRespuestas) {
      listaRespuestas.sort((a, b) {
        final fechaA = (a.data() as Map<String, dynamic>?)?['fecha'] as Timestamp?;
        final fechaB = (b.data() as Map<String, dynamic>?)?['fecha'] as Timestamp?;
        if (fechaA == null && fechaB == null) return 0;
        if (fechaA == null) return -1; // Sort nulls first if desired, or 1 for last
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

      // --- Main Comment Card ---
      comentariosWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Card(
            elevation: esUsuarioActual ? 0 : 1,
            // Use M3 container colors for background differentiation
            color: esUsuarioActual ? colorScheme.primaryContainer.withOpacity(0.4) : colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row( // Header
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
                  Text(comentarioTexto, style: textTheme.bodyMedium), // Content
                  const SizedBox(height: 10),
                  Row( // Footer
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatearFecha(fecha), style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                      TextButton.icon(
                        onPressed: () => _mostrarDialogoRespuesta(doc.id, nombreUsuario),
                        icon: Icon(Icons.reply_rounded, size: 16, color: colorScheme.primary), // Use rounded icon
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
        // Animate the main comment card
        .animate().fadeIn(duration: 400.ms, delay: (50 * i).ms).slideY(begin: 0.1, curve: Curves.easeOutCubic)
      );

      // --- Replies Section ---
      if (respuestasPorComentario.containsKey(doc.id)) {
        comentariosWidgets.add(
          Padding(
             padding: const EdgeInsets.only(left: 32.0, top: 0, bottom: 4, right: 0), // Indent replies
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: respuestasPorComentario[doc.id]!.asMap().entries.map((entry) {
                 int replyIndex = entry.key; DocumentSnapshot respuestaDoc = entry.value;
                 final respuestaData = respuestaDoc.data() as Map<String, dynamic>?; if (respuestaData == null) return const SizedBox.shrink();

                 final fechaRespuesta = respuestaData['fecha'] != null ? (respuestaData['fecha'] as Timestamp).toDate() : DateTime.now();
                 final esUsuarioActualRespuesta = _uidActual != null && respuestaData['usuarioId'] == _uidActual;
                 final nombreUsuarioRespuesta = respuestaData['usuarioNombre'] ?? 'Usuario';
                 final respuestaTexto = respuestaData['comentario'] ?? '';

                 // --- Reply Card ---
                 return Padding(
                   padding: const EdgeInsets.only(top: 8.0),
                   child: Card(
                      elevation: 0,
                      // Use outlined card style for replies
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5))),
                      // Optional subtle background for user's reply
                      color: esUsuarioActualRespuesta ? colorScheme.secondaryContainer.withOpacity(0.3) : null,
                     child: Padding(
                       padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Row( // Reply Header
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
                           Text(respuestaTexto, style: textTheme.bodySmall), // Reply Content
                           const SizedBox(height: 6),
                           Align(alignment: Alignment.centerRight, child: Text(_formatearFecha(fechaRespuesta), style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant))), // Reply Date
                         ],
                       ),
                     ),
                   ),
                 )
                 // Animate the reply card
                 .animate().fadeIn(duration: 300.ms, delay: (50 * replyIndex).ms).slideX(begin: 0.1, curve: Curves.easeOut);
               }).toList(),
             ),
           ),
        );
      }
    }
    return comentariosWidgets;
  }

  // --- Shimmer Placeholder for Comments ---
  Widget _buildShimmerCommentList(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Use M3 container colors for shimmer base/highlight
    final shimmerBaseColor = colorScheme.surfaceContainerHighest;
    final shimmerHighlightColor = colorScheme.surfaceContainer;

    return Shimmer.fromColors(
      baseColor: shimmerBaseColor, highlightColor: shimmerHighlightColor,
      child: Column(
        children: List.generate(3, (index) => Padding( // Generate a few placeholders
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Card(
             elevation: 0,
             color: shimmerBaseColor, // Use base color for card background
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

  // --- Build Main Widget ---
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      // No explicit background color needed, uses theme's Scaffold background
      body: GestureDetector(
         onTap: () => FocusScope.of(context).unfocus(), // Dismiss keyboard on tap outside
         child: CustomScrollView(
          controller: _scrollController,
          // Use bouncing physics for iOS-like overscroll, AlwaysScrollable to enable even if content fits
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // --- Collapsing App Bar with Image ---
            SliverAppBar(
              expandedHeight: screenHeight * 0.35, // Adaptable height
              pinned: true, // Keep AppBar visible
              stretch: true, // Allow image stretching
              backgroundColor: colorScheme.surface, // Use surface color for AppBar background
              foregroundColor: colorScheme.onSurface, // Ensure icons/text have contrast
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12), // Adjust title padding
                title: Text(
                  widget.receta.nombre,
                  // Title style automatically adapts based on AppBar collapse state and theme
                  // style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface)
                ),
                centerTitle: true,
                background: Hero(
                  // Ensure unique tag matches ListaRecetas
                  tag: 'recipe_image_${widget.receta.id}',
                  child: Image.network(
                     widget.receta.urlImagen, fit: BoxFit.cover,
                     // Shimmer loading placeholder for image
                     loadingBuilder: (context, child, progress) => progress == null
                         ? child
                         : Shimmer.fromColors(
                             baseColor: colorScheme.surfaceContainerHighest,
                             highlightColor: colorScheme.surfaceContainer,
                             child: Container(color: Colors.white) // Base for shimmer
                           ),
                     // Error placeholder for image
                     errorBuilder: (context, error, stack) => Container(
                       color: colorScheme.surfaceContainer, // Use a container color
                       child: Center(child: Icon(Icons.broken_image_outlined, color: colorScheme.onSurfaceVariant, size: 50)),
                     ),
                  ),
                ),
                 stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle], // Standard stretch modes
              ),
            ),

            // --- Main Content Area ---
            SliverPadding( // Add padding around the main content list
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // --- Basic Info (Time/Rating) ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [ Icon(Icons.timer_outlined, color: colorScheme.primary, size: 20), const SizedBox(width: 8), Text("${widget.receta.tiempoMinutos} min", style: textTheme.titleMedium)]),
                      Row(children: List.generate(5, (i) => Icon(i < widget.receta.calificacion ? Icons.star_rounded : Icons.star_border_rounded, color: colorScheme.primary, size: 22))
                          .animate(interval: 50.ms).fadeIn(delay: 300.ms)), // Animate stars
                    ],
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1), // Animate row
                  const Divider(height: 32, thickness: 1), // Use DividerTheme from main theme

                  // --- Ingredientes ---
                  Text("Ingredientes", style: textTheme.titleLarge), // Use M3 title styles
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8.0, runSpacing: 6.0,
                    children: widget.receta.ingredientes.map((ing) => Chip(
                      label: Text(ing),
                      backgroundColor: colorScheme.secondaryContainer.withOpacity(0.7), // Use M3 container color
                      side: BorderSide.none, // Filled chip style
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // M3 chip shape
                    )).toList()
                  ).animate().fadeIn(delay: 400.ms), // Animate ingredients section
                  const Divider(height: 32, thickness: 1),

                  // --- Descripción ---
                  Text("Descripción", style: textTheme.titleLarge),
                  const SizedBox(height: 10),
                  Text(
                    widget.receta.descripcion,
                    style: textTheme.bodyLarge?.copyWith(height: 1.5), // Use M3 body styles
                    textAlign: TextAlign.justify,
                  ).animate().fadeIn(delay: 500.ms), // Animate description
                  const SizedBox(height: 30),

                  // --- Botón Iniciar ---
                  Center(
                    child: ElevatedButton.icon(
                      // Style inherits from ElevatedButtonTheme in main theme
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14), textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PasosRecetaScreen(receta: widget.receta))),
                      icon: const Icon(Icons.play_circle_fill_rounded), // Use rounded icon
                      label: const Text("Iniciar Preparación"),
                    )
                  ).animate().fadeIn(delay: 600.ms).shake(hz: 3, duration: 400.ms), // Animate button
                  const Divider(height: 40, thickness: 1),

                  // --- SECCIÓN DE COMENTARIOS ---
                  Text("Comentarios", style: textTheme.titleLarge), // Use M3 title style
                  const SizedBox(height: 15),

                  // --- Formulario para nuevo comentario ---
                  Container(
                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                     decoration: BoxDecoration(
                       color: colorScheme.surfaceContainerHighest, // Use M3 container color
                       borderRadius: BorderRadius.circular(30) // Fully rounded input field
                     ),
                     child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center, // Align items vertically
                        children: [
                          Expanded(child: TextField(
                            controller: _comentarioController, maxLines: null, minLines: 1, keyboardType: TextInputType.multiline, textInputAction: TextInputAction.newline,
                            style: textTheme.bodyMedium,
                            decoration: InputDecoration(
                              hintText: "Añade un comentario...",
                              hintStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant), // Hint text style
                              border: InputBorder.none, // No border inside the container
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12), // Adjust padding
                            ),
                            onChanged: (_) => setState(() {}), // Update state to enable/disable send button
                          )),
                          // Send Button
                          IconButton(
                            icon: const Icon(Icons.send_rounded), // Use rounded icon
                            color: _comentarioController.text.trim().isEmpty ? colorScheme.onSurfaceVariant : colorScheme.primary, // Enable/disable color
                            visualDensity: VisualDensity.compact,
                            tooltip: "Enviar",
                            onPressed: _comentarioController.text.trim().isEmpty ? null : () { _agregarComentario(_comentarioController.text.trim()); },
                          ),
                     ]),
                  ).animate().fadeIn(delay: 700.ms), // Animate comment input
                  const SizedBox(height: 25),

                  // --- Lista de Comentarios ---
                  _cargaInicial
                      ? _buildShimmerCommentList(context) // Show themed shimmer
                      : _comentarios.isEmpty
                          ? Padding( // Empty State
                              padding: const EdgeInsets.symmetric(vertical: 40.0),
                              child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Icon(Icons.chat_bubble_outline_rounded, size: 50, color: colorScheme.secondary),
                                const SizedBox(height: 16),
                                Text('No hay comentarios aún.\n¡Sé el primero!', style: textTheme.titleMedium?.copyWith(color: colorScheme.secondary), textAlign: TextAlign.center),
                              ])),
                            ).animate().fadeIn(delay: 200.ms)
                          : Column( // Comment List + Load More Indicator
                              children: [
                                ..._buildComentariosAgrupados(context), // Uses internal animation
                                // Loading indicator for pagination
                                if (_cargandoMas) const Padding(padding: EdgeInsets.symmetric(vertical: 20.0), child: Center(child: CircularProgressIndicator(strokeWidth: 2.0))),
                                // End of comments indicator
                                if (_todosCargados && _comentarios.isNotEmpty && !_cargandoMas)
                                   Padding(padding: const EdgeInsets.symmetric(vertical: 30.0), child: Center(child: Text("—— Fin ——", style: textTheme.labelMedium?.copyWith(color: colorScheme.outline)))).animate().fadeIn(),
                              ],
                            ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Widget StatefulWidget para el contenido del diálogo de respuesta (M3 Themed) ---
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
     final colorScheme = Theme.of(context).colorScheme; // Get theme

    // Use standard M3 AlertDialog
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), // M3 Dialog shape
      title: Text('Responder a ${widget.nombreUsuarioPadre}'),
      content: TextField(
        controller: _respuestaController,
        decoration: const InputDecoration(
          hintText: 'Escribe tu respuesta...',
          border: OutlineInputBorder(), // Uses themed OutlineInputBorder
        ),
        maxLines: null, minLines: 2, // Allow multiple lines
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        autofocus: true,
        onChanged: (_) => setState(() {}), // Update state to enable/disable button
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _estaEnviando ? null : () { Navigator.of(context).pop(); }, // Disable while sending
          child: const Text('Cancelar'),
        ),
        TextButton(
          // Disable button if text is empty or sending
          onPressed: _respuestaController.text.trim().isEmpty || _estaEnviando ? null : () async {
            final respuestaTexto = _respuestaController.text.trim();
            setState(() => _estaEnviando = true);
            try { await widget.onResponder(respuestaTexto); }
            catch (e) {
               print("Error en callback onResponder: $e");
               // Show themed error snackbar
               if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al enviar respuesta", style: TextStyle(color: colorScheme.onError)), backgroundColor: colorScheme.error));
            } finally {
               if (mounted) { setState(() => _estaEnviando = false); }
            }
            if (mounted) { Navigator.of(context).pop(); } // Close dialog on success or final attempt
          },
          child: _estaEnviando
              // Show progress indicator while sending
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary))
              : const Text('Responder'),
        ),
      ],
    );
  }
}