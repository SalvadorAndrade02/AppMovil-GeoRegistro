import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'preview_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    _controller = CameraController(cameras[0], ResolutionPreset.high);
    await _controller!.initialize();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _takeCapture() async {
    if (_isProcessing) return; // Evita múltiples clics
    setState(() => _isProcessing = true);

    try {
      // 1. Tomar la foto
      final XFile image = await _controller!.takePicture();

      // 2. Obtener GPS
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
      );

      Position position =
          await Geolocator.getCurrentPosition(
            locationSettings: locationSettings,
          ).timeout(
            const Duration(seconds: 5),
            onTimeout: () => Position(
              latitude: 0.0,
              longitude: 0.0,
              timestamp: DateTime.now(),
              accuracy: 0,
              altitude: 0,
              heading: 0,
              speed: 0,
              speedAccuracy: 0,
              altitudeAccuracy: 0,
              headingAccuracy: 0,
            ),
          );

      // 3. ¡EL SALTO! (Ahora sí, al final porque ya tenemos los datos)
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PreviewScreen(
            imagePath: image.path,
            lat: position.latitude,
            lng: position.longitude,
            direccion: "Dirección de ejemplo",
          ),
        ),
      );
    } catch (e) {
      debugPrint("Error en captura: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          CameraPreview(_controller!),
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: FloatingActionButton(
              onPressed: _takeCapture,
              backgroundColor: Colors.white,
              child: _isProcessing
                  ? const CircularProgressIndicator()
                  : const Icon(Icons.camera_alt, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
