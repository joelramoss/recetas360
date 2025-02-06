import 'package:flutter/material.dart';

class Lenguajes extends StatefulWidget {
  const Lenguajes({Key? key}) : super(key: key);

  @override
  _LenguajesState createState() => _LenguajesState();
}

class _LenguajesState extends State<Lenguajes> {
  // Selección inicial (puedes cambiarla o dejarla nula)
  String _selectedLanguage = 'Castellano';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fondo blanco para un estilo minimalista
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Lenguajes",
          style: TextStyle(
            color: Colors.black, // Texto negro para un buen contraste
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.black, // Íconos en negro
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  // Padding para que el contenido no toque los bordes de la pantalla
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: Container(
                      width: 320, // Ancho del contenedor
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.white, // Fondo blanco para el contenedor
                        borderRadius: BorderRadius.zero, // Bordes cuadrados
                        border: Border.all(
                          color: Colors.black.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Etiqueta (opcional)
                          const Text(
                            'Selecciona un idioma:',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Menú desplegable para seleccionar el lenguaje
                          DropdownButton<String>(
                            value: _selectedLanguage,
                            icon: const Icon(Icons.arrow_downward, color: Colors.black),
                            iconSize: 24,
                            elevation: 16,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            underline: Container(
                              height: 2,
                              color: Colors.black.withOpacity(0.2),
                            ),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedLanguage = newValue!;
                              });
                            },
                            items: <String>['Castellano', 'Catalan', 'Ingles']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                          // Botón "Aplicar"
                          ElevatedButton(
                            onPressed: () {
                              // Acción para aplicar el idioma seleccionado.
                              // Puedes guardar la preferencia o actualizar la interfaz según sea necesario.
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black, // Botón negro
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero, // Bordes cuadrados
                              ),
                            ),
                            child: const Text(
                              'Aplicar',
                              style: TextStyle(
                                color: Colors.white, // Texto blanco en el botón negro
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
            );
          },
        ),
      ),
    );
  }
}
