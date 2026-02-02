import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Función para subir la imagen y los datos
  Future<void> uploadCapture({
    required String localPath,
    required double lat,
    required double lng,
    required String note,
  }) async {
    try {
      // 1. Crear nombre único para la imagen
      String fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
      File file = File(localPath);

      // 2. Subir a Firebase Storage
      Reference ref = _storage.ref().child('capturas/$fileName');
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      
      // 3. Obtener el link público
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // 4. Guardar en Firestore
      await _firestore.collection('capturas').add({
        'url': downloadUrl,
        'latitud': lat,
        'longitud': lng,
        'notas': note,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception("Error al subir a Firebase: $e");
    }
  }
}