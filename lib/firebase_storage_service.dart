import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import 'dart:typed_data';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadImage({
    required Uint8List imageBytes,
    required String reportId,
    required int index,
  }) async {
    try {
      final compressedBytes = await _compressImage(imageBytes);
      final ref = _storage.ref('reports/$reportId/images/$index.jpg');
      final uploadTask = ref.putData(compressedBytes);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<Uint8List> _compressImage(Uint8List bytes) async {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return bytes;
      
      final compressed = img.copyResize(
        image,
        width: 800,
        height: 800,
        maintainAspect: true,
      );
      
      return Uint8List.fromList(img.encodeJpg(compressed, quality: 80));
    } catch (e) {
      return bytes;
    }
  }
}