import 'package:cloud_firestore/cloud_firestore.dart';

class CaptureModel {
  String imagePath;
  double latitude;
  double longitude;
  DateTime timestamp;
  String observations;
  String? firebaseUrl; // Se llenará al subir a la nube

  CaptureModel({
    required this.imagePath,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.observations = "",
    this.firebaseUrl,
  });

  // Convertir a Mapa para Firebase
  Map<String, dynamic> toJson() => {
    'lat': latitude,
    'lng': longitude,
    'time': Timestamp.fromDate(timestamp),
    'note': observations,
    'url': firebaseUrl,
  };
}