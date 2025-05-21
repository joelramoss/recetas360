import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickImage(
      {required ImageSource source,
      int imageQuality = 70,
      double maxWidth = 1024,
      BuildContext? context // Opcional, para mostrar Snackbars
      }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
      );
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      print("Error al seleccionar imagen: $e");
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Error al seleccionar imagen: ${e.toString()}",
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onError)),
              backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    }
    return null;
  }

  void showImageSourceActionSheet(
      {required BuildContext context,
      required Function(File) onImageSelected}) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('Galería'),
                    onTap: () async {
                      Navigator.of(context).pop();
                      File? file = await pickImage(source: ImageSource.gallery, context: context);
                      if (file != null) {
                        onImageSelected(file);
                      }
                    }),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Cámara'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    File? file = await pickImage(source: ImageSource.camera, context: context);
                    if (file != null) {
                      onImageSelected(file);
                    }
                  },
                ),
              ],
            ),
          );
        });
  }
}