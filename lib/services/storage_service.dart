import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

/// Servicio para manejar operaciones de Firebase Storage
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Sube una imagen de producto a Firebase Storage
  /// Retorna la URL de descarga si es exitoso, null si falla
  Future<String?> uploadProductImage({
    required String productId,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      // Crear referencia en Storage: products/{productId}/{fileName}
      final ref = _storage.ref().child('products/$productId/$fileName');

      // Subir imagen
      await ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Obtener URL de descarga
      final downloadUrl = await ref.getDownloadURL();
      print('✅ Imagen subida exitosamente: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Error al subir imagen: $e');
      return null;
    }
  }

  /// Elimina una imagen de producto de Firebase Storage
  Future<void> deleteProductImage(String imageUrl) async {
    try {
      // Obtener referencia desde la URL
      final ref = _storage.refFromURL(imageUrl);

      // Eliminar imagen
      await ref.delete();
      print('✅ Imagen eliminada exitosamente');
    } catch (e) {
      print('❌ Error al eliminar imagen: $e');
      // No lanzar error, solo loguear
    }
  }
}
