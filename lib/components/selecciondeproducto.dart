import 'package:flutter/material.dart';
import 'package:recetas360/components/apiservice.dart';
import 'producto.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Widget Stateful para el contenido del diálogo de selección
class _ProductSelectionDialogContent extends StatefulWidget {
  final String ingrediente;

  const _ProductSelectionDialogContent({required this.ingrediente});

  @override
  _ProductSelectionDialogContentState createState() =>
      _ProductSelectionDialogContentState();
}

class _ProductSelectionDialogContentState
    extends State<_ProductSelectionDialogContent> {
  final ApiService _apiService = ApiService();
  List<Producto> _productos = [];
  int _paginaActual = 1;
  bool _estaCargando = false;
  bool _cargaInicialCompleta = false;
  bool _todosLosProductosCargados = false;
  String? _errorMensaje;

  @override
  void initState() {
    super.initState();
    _buscarProductos(esCargaInicial: true);
  }

  Future<void> _buscarProductos({bool esCargaInicial = false}) async {
    if (_estaCargando || (_todosLosProductosCargados && !esCargaInicial)) return;

    setState(() {
      _estaCargando = true;
      if (esCargaInicial) {
        _errorMensaje = null;
        _productos.clear(); // Limpiar productos para nueva búsqueda/carga inicial
        _paginaActual = 1;
        _todosLosProductosCargados = false;
        _cargaInicialCompleta = false;
      }
    });

    try {
      final nuevosProductos = await _apiService.buscarProductos(
          widget.ingrediente,
          page: _paginaActual);
      if (!mounted) return;

      setState(() {
        _productos.addAll(nuevosProductos);
        if (nuevosProductos.isEmpty || nuevosProductos.length < 5) { // Asumiendo page_size=5
          _todosLosProductosCargados = true;
        }
        _paginaActual++;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMensaje = "Error: ${e.toString()}";
      });
      print("Error buscando productos: $e");
    } finally {
      if (!mounted) return;
      setState(() {
        _estaCargando = false;
        _cargaInicialCompleta = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (!_cargaInicialCompleta && _estaCargando) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: colorScheme.primary),
            const SizedBox(height: 20),
            Text(
              "Buscando productos...",
              style: textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    if (_errorMensaje != null) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: colorScheme.error, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMensaje!,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onErrorContainer),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _buscarProductos(esCargaInicial: true),
              child: const Text("Reintentar"),
            )
          ],
        ),
      );
    }
    
    if (_productos.isEmpty && _cargaInicialCompleta) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: colorScheme.secondary),
            const SizedBox(height: 16),
            Text(
              "No se encontraron productos para \"${widget.ingrediente}\"",
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.maxFinite,
      // Ajustar altura o usar Column para permitir que crezca
      child: Column(
        mainAxisSize: MainAxisSize.min, // Para que el Column no ocupe toda la altura del diálogo
        children: [
          Flexible( // Para que el ListView no cause overflow si hay muchos items
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _productos.length,
              itemBuilder: (_, index) {
                final producto = _productos[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  title: Text(producto.nombre, style: textTheme.bodyLarge),
                  subtitle: Text(
                    '${producto.valorEnergetico.toStringAsFixed(0)} kcal, ${producto.proteinas.toStringAsFixed(1)}g P, ${producto.carbohidratos.toStringAsFixed(1)}g C, ${producto.grasas.toStringAsFixed(1)}g G',
                    style: textTheme.bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  onTap: () {
                    Navigator.of(context).pop(producto);
                  },
                ).animate().fadeIn(delay: (50 * index).ms);
              },
            ),
          ),
          if (_estaCargando && !_cargaInicialCompleta) // Indicador de carga para "cargar más"
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: colorScheme.primary),
            ),
          if (!_todosLosProductosCargados && !_estaCargando && _cargaInicialCompleta)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 0), // Ajuste de padding
              child: TextButton(
                onPressed: () => _buscarProductos(),
                child: const Text("Cargar más productos"),
              ),
            ),
        ],
      ),
    );
  }
}

// Función principal para mostrar el diálogo
Future<Producto?> showProductoSelection(
    BuildContext context, String ingrediente) async {
  return showDialog<Producto>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Selecciona para "$ingrediente"'),
        contentPadding: const EdgeInsets.symmetric(vertical: 20.0), // Ajustar padding del content
        content: _ProductSelectionDialogContent(ingrediente: ingrediente),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text("Cancelar"),
          ),
        ],
      );
    },
  );
}