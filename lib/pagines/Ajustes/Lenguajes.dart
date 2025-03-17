import 'package:flutter/material.dart';

class Lenguajes extends StatefulWidget {
  const Lenguajes({Key? key}) : super(key: key);

  @override
  _LenguajesState createState() => _LenguajesState();
}

class _LenguajesState extends State<Lenguajes> {
  String _selectedLanguage = 'Castellano';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo degradado
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
        child: SafeArea(
          child: Column(
            children: [
              // Encabezado de 50 px
              Container(
                width: double.infinity,
                height: 50,
                alignment: Alignment.center,
                child: const Text(
                  "Lenguajes",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 4,
                        color: Colors.black45,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
              ),
              // Contenedor central con Card
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
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Selecciona un idioma:',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
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
                          ElevatedButton(
                            onPressed: () {
                              // Aquí aplicas la selección, por ejemplo, guardándola o actualizando la interfaz.
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 40,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Aplicar',
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
}
