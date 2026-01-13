import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Helper para subir imágenes a Supabase Storage
class ImageUploadHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Selecciona y recorta una imagen de la galería
  static Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        // Recortar la imagen
        return await _cropImage(image.path);
      }
      return null;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  /// Selecciona y recorta una imagen de la cámara
  static Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        // Recortar la imagen
        return await _cropImage(image.path);
      }
      return null;
    } catch (e) {
      print('Error taking photo: $e');
      return null;
    }
  }

  /// Recorta una imagen
  static Future<File?> _cropImage(String imagePath) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Recortar Imagen',
            toolbarColor: const Color(0xff721c80),
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: false,
            hideBottomControls: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          IOSUiSettings(
            title: 'Recortar Imagen',
            aspectRatioLockEnabled: false,
            resetAspectRatioEnabled: true,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
        ],
      );

      if (croppedFile != null) {
        return File(croppedFile.path);
      }
      return null;
    } catch (e) {
      print('Error cropping image: $e');
      // Si falla el recorte, devolver la imagen original
      return File(imagePath);
    }
  }

  /// Sube una imagen al bucket de productos
  static Future<String?> uploadProductImage(File imageFile, int productId) async {
    try {
      final fileName = 'product_${productId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bytes = await imageFile.readAsBytes();

      await Supabase.instance.client.storage
          .from('products')
          .uploadBinary(fileName, bytes);

      // Obtener la URL pública
      final url = Supabase.instance.client.storage
          .from('products')
          .getPublicUrl(fileName);

      return url;
    } catch (e) {
      print('Error uploading product image: $e');
      return null;
    }
  }

  /// Sube una imagen al bucket de servicios
  static Future<String?> uploadServiceImage(File imageFile, int serviceId) async {
    try {
      final fileName = 'service_${serviceId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bytes = await imageFile.readAsBytes();

      await Supabase.instance.client.storage
          .from('services')
          .uploadBinary(fileName, bytes);

      // Obtener la URL pública
      final url = Supabase.instance.client.storage
          .from('services')
          .getPublicUrl(fileName);

      return url;
    } catch (e) {
      print('Error uploading service image: $e');
      return null;
    }
  }

  /// Elimina una imagen del bucket de productos
  static Future<bool> deleteProductImage(String imageUrl) async {
    try {
      // Extraer el nombre del archivo de la URL
      final uri = Uri.parse(imageUrl);
      final fileName = uri.pathSegments.last;

      await Supabase.instance.client.storage
          .from('products')
          .remove([fileName]);

      return true;
    } catch (e) {
      print('Error deleting product image: $e');
      return false;
    }
  }

  /// Elimina una imagen del bucket de servicios
  static Future<bool> deleteServiceImage(String imageUrl) async {
    try {
      // Extraer el nombre del archivo de la URL
      final uri = Uri.parse(imageUrl);
      final fileName = uri.pathSegments.last;

      await Supabase.instance.client.storage
          .from('services')
          .remove([fileName]);

      return true;
    } catch (e) {
      print('Error deleting service image: $e');
      return false;
    }
  }

  /// Muestra un diálogo para seleccionar fuente de imagen
  static Future<File?> showImageSourceDialog(BuildContext context) async {
    return await showDialog<File?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccionar imagen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xff721c80)),
                title: const Text('Galería'),
                onTap: () async {
                  final file = await pickImageFromGallery();
                  if (context.mounted) {
                    Navigator.pop(context, file);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xff721c80)),
                title: const Text('Cámara'),
                onTap: () async {
                  final file = await pickImageFromCamera();
                  if (context.mounted) {
                    Navigator.pop(context, file);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }
}
