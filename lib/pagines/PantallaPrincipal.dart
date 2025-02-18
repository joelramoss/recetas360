import 'package:flutter/material.dart';
import '../components/ListaRecetas.dart';

class DeliveryStyleRecetaModified extends StatefulWidget {
  const DeliveryStyleRecetaModified({Key? key}) : super(key: key);

  @override
  State<DeliveryStyleRecetaModified> createState() =>
      _DeliveryStyleRecetaModifiedState();
}

class _DeliveryStyleRecetaModifiedState
    extends State<DeliveryStyleRecetaModified> {
  String? categoriaSeleccionada;
  String? gastronomiaSeleccionada;

  // Lista de categorías con URL de imagen
  final List<_Categoria> categorias = [
    _Categoria(
      nombre: "Carne",
      urlImagen:
          "https://www.saborusa.com/wp-content/uploads/2020/12/Conoce-el-termino-ideal-de-la-carne-segun-su-tamanio_1.png",
    ),
    _Categoria(
      nombre: "Pescado",
      urlImagen:
          "https://images.unsplash.com/photo-1550258987-190a2d41a8ba?auto=format&fit=crop&w=200&q=60",
    ),
    _Categoria(
      nombre: "Verduras",
      urlImagen:
          "https://images.unsplash.com/photo-1550258987-190a2d41a8ba?auto=format&fit=crop&w=200&q=60",
    ),
    _Categoria(
      nombre: "Lácteos",
      urlImagen:
          "https://images.unsplash.com/photo-1550258987-190a2d41a8ba?auto=format&fit=crop&w=200&q=60",
    ),
    _Categoria(
      nombre: "Cereales",
      urlImagen:
          "https://images.unsplash.com/photo-1550258987-190a2d41a8ba?auto=format&fit=crop&w=200&q=60",
    ),
  ];

  // Opciones de gastronomía
  final List<String> opcionesGastronomia = [
    "Gastronomía Europea",
    "Gastronomía Asiática",
    "Gastronomía Americana",
    "Gastronomía Africana",
    "Gastronomía Oceánica",
    "Todos"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ------------------- Drawer con icono de usuario -------------------
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.orangeAccent,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.orangeAccent,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Usuario",
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Perfil"),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Ajustes"),
              onTap: () {},
            ),
          ],
        ),
      ),

      // ------------------- AppBar con icono de menú -------------------
      appBar: AppBar(
        title: const Text("Recetas"),
        backgroundColor: Colors.orangeAccent,
      ),

      // ------------------- Cuerpo con degradado de fondo -------------------
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.pink.shade50,
              Colors.orange.shade100,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ------------------- Categorías (con imágenes en vez de texto) -------------------
                Text(
                  "Categorías",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categorias.length,
                    itemBuilder: (context, index) {
                      final cat = categorias[index];
                      bool isSelected = categoriaSeleccionada == cat.nombre;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            categoriaSeleccionada = cat.nombre;
                            gastronomiaSeleccionada = null;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          width: 70,
                          child: Stack(
                            children: [
                              // Imagen circular
                              ClipRRect(
                                borderRadius: BorderRadius.circular(35),
                                child: Image.network(
                                  cat.urlImagen,
                                  fit: BoxFit.cover,
                                  width: 70,
                                  height: 70,
                                ),
                              ),
                              // Si está seleccionada, añadimos un borde anaranjado
                              if (isSelected)
                                Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.orange,
                                      width: 3,
                                    ),
                                    borderRadius: BorderRadius.circular(35),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // ------------------- Grid de Gastronomía -------------------
                if (categoriaSeleccionada != null) ...[
                  Text(
                    "Gastronomía",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: opcionesGastronomia.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 3,
                    ),
                    itemBuilder: (context, index) {
                      final opcion = opcionesGastronomia[index];
                      bool isSelected = gastronomiaSeleccionada == opcion;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            gastronomiaSeleccionada = opcion;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.orangeAccent
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.orange
                                  : Colors.grey.shade300,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              opcion,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],

                const SizedBox(height: 32),

                // ------------------- Botón para "Ver Recetas" -------------------
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      // Navega a la pantalla de lista de recetas
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ListaRecetas(),
                        ),
                      );
                    },
                    child: const Text("Ver Recetas"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Clase interna para manejar nombre + URL de imagen de categoría
class _Categoria {
  final String nombre;
  final String urlImagen;
  _Categoria({required this.nombre, required this.urlImagen});
}
