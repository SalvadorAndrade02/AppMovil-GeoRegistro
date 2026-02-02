import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // El archivo que generó flutterfire
import 'screens/camera_screen.dart'; // Tu pantalla de cámara

void main() async {
  // Aseguramos que los widgets carguen antes de iniciar Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializamos Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ImageoEdit GPS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      // AQUÍ ES DONDE CAMBIAMOS EL CONTADOR POR TU CÁMARA
      home: const CameraScreen(), 
    );
  }
}