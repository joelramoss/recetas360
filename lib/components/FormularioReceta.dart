import 'package:flutter/material.dart';

class FormularioReceta extends StatefulWidget {
  final TextEditingController nombreReceta;
  final TextEditingController urlImagen;
  final TextEditingController descripcion;
  final TextEditingController tiempoPreparacion;
  final String categoriaSeleccionada;
  final String gastronomiaSeleccionada;
  final List<String> opcionesGastronomia;
  final Function(Map<String, dynamic>) accionGuardar;
  final VoidCallback accionCancelar;

  const FormularioReceta({
    Key? key,
    required this.nombreReceta,
    required this.urlImagen,
    required this.descripcion,
    required this.tiempoPreparacion,
    required this.categoriaSeleccionada,
    required this.gastronomiaSeleccionada,
    required this.opcionesGastronomia,
    required this.accionGuardar,
    required this.accionCancelar,
  }) : super(key: key);

  @override
  State<FormularioReceta> createState() => _EstadoFormularioReceta();
}

class _EstadoFormularioReceta extends State<FormularioReceta> {
  final _formKey = GlobalKey<FormState>();
  late String _gastronomiaSeleccionada;

  @override
  void initState() {
    super.initState();
    _gastronomiaSeleccionada = widget.gastronomiaSeleccionada;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text(
        'Crear Receta',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mostrar el tipo de alimento seleccionado (si no es "Sin tipo de alimento")
              if (widget.categoriaSeleccionada != "Sin tipo de alimento") ...[
                Row(
                  children: [
                    const Text(
                      'Tipo de Alimento: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      widget.categoriaSeleccionada,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],

              // Dropdown para gastronomía
              DropdownButtonFormField<String>(
                value: _gastronomiaSeleccionada,
                items: widget.opcionesGastronomia.map((String opcion) {
                  return DropdownMenuItem<String>(
                    value: opcion,
                    child: Text(opcion),
                  );
                }).toList(),
                onChanged: (nuevoValor) {
                  setState(() {
                    _gastronomiaSeleccionada = nuevoValor!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Tipo de Gastronomía',
                ),
              ),
              const SizedBox(height: 10),

              // Campos de la receta
              TextFormField(
                controller: widget.nombreReceta,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la Receta',
                ),
                validator: (valor) {
                  if (valor == null || valor.isEmpty) {
                    return 'Por favor, ingresa el nombre de la receta';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: widget.urlImagen,
                decoration: const InputDecoration(
                  labelText: 'URL de la Imagen',
                ),
                validator: (valor) {
                  if (valor == null || valor.isEmpty) {
                    return 'Por favor, ingresa la URL de la imagen';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: widget.descripcion,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                ),
                maxLines: 3,
                validator: (valor) {
                  if (valor == null || valor.isEmpty) {
                    return 'Por favor, ingresa una descripción';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: widget.tiempoPreparacion,
                decoration: const InputDecoration(
                  labelText: 'Tiempo de Preparación (min)',
                ),
                keyboardType: TextInputType.number,
                validator: (valor) {
                  if (valor == null || valor.isEmpty) {
                    return 'Por favor, ingresa el tiempo de preparación';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.accionCancelar,
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orangeAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final receta = {
                'nombre': widget.nombreReceta.text,
                'url': widget.urlImagen.text,
                'descripcion': widget.descripcion.text,
                'tiempoPreparacion': widget.tiempoPreparacion.text,
                'categoria': widget.categoriaSeleccionada,
                'gastronomia': _gastronomiaSeleccionada,
              };
              widget.accionGuardar(receta);
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
