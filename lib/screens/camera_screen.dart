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
  double _baseZoomLevel =
      1.0; // Para recordar el zoom antes de empezar el gesto
  double _currentZoomLevel = 1.0;
  double _maxAvailableZoom = 1.0;
  double _minAvailableZoom = 1.0;
  int _selectedCameraIndex = 0; // 0 para trasera, 1 para frontal
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  // Inicializa la cámara
  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }

    _controller = CameraController(
      cameras[_selectedCameraIndex],
      ResolutionPreset.max,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg, //formato de fotos JPEG
    );

    try {
      //PRIMERO encendemos la cámara
      await _controller!.initialize();

      //DESPUÉS pedimos los datos de Zoom (ya con la cámara encendida)
      _maxAvailableZoom = await _controller!.getMaxZoomLevel();
      _minAvailableZoom = await _controller!.getMinZoomLevel();
    } catch (e) {
      debugPrint("Error al inicializar cámara: $e");
    }

    if (!mounted) return;
    setState(() {});
  }

  // Función para cambiar de cámara
  Future<void> _toggleCamera() async {
    final cameras = await availableCameras();
    if (cameras.length < 2) return; // No hay cámara frontal

    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % cameras.length;
    });

    _currentZoomLevel = 1.0;
    await _initCamera();
  }

  Future<void> _takeCapture() async {
    if (_isProcessing) return; // Evita múltiples clics
    setState(() => _isProcessing = true);

    try {
      // Tomar la foto
      final XFile image = await _controller!.takePicture();

      // Obtener GPS
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

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PreviewScreen(
            imagePath: image.path,
            lat: position.latitude,
            lng: position.longitude,
            direccion: "Dirección de ejemplo",
            isFrontCamera: _selectedCameraIndex == 1,
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
          // LA CÁMARA
          Center(
            child: GestureDetector(
              onScaleStart: (details) => _baseZoomLevel = _currentZoomLevel,
              onScaleUpdate: (details) async {
                double newZoom = _baseZoomLevel * details.scale;
                if (newZoom < _minAvailableZoom) newZoom = _minAvailableZoom;
                if (newZoom > _maxAvailableZoom) newZoom = _maxAvailableZoom;

                setState(() {
                  _currentZoomLevel = newZoom;
                });

                // Aplicamos el zoom a la cámara
                await _controller!.setZoomLevel(newZoom);
              },
              child: _controller!.value.isInitialized
                  ? ClipRect(
                      // Recorta los sobrantes para que no se salga de la pantalla
                      child: Transform.scale(
                        scale: 1.0, // Asegúrate de que el scale inicial sea 1
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: 1 / _controller!.value.aspectRatio,
                            child: CameraPreview(_controller!),
                          ),
                        ),
                      ),
                    )
                  : const CircularProgressIndicator(),
            ),
            /* child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(
                  _selectedCameraIndex == -1 ? 3.14159 : 0,
                ),
                child: CameraPreview(_controller!),
              ), */
          ),
          //),

          // CONTROL DE ZOOM
          Positioned(
            bottom: 120,
            left: 40,
            right: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.zoom_out, color: Colors.white, size: 20),
                  Expanded(
                    child: Slider(
                      value: _currentZoomLevel,
                      min: _minAvailableZoom,
                      max: _maxAvailableZoom,
                      activeColor: Colors.white,
                      inactiveColor: Colors.white30,
                      onChanged: (value) async {
                        setState(() => _currentZoomLevel = value);
                        await _controller!.setZoomLevel(value);
                      },
                    ),
                  ),
                  const Icon(Icons.zoom_in, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),

          // BOTONES DE ACCIÓN
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const SizedBox(width: 60),
                // BOTÓN TOMAR FOTO
                FloatingActionButton(
                  heroTag: "take_pic",
                  onPressed: _takeCapture,
                  backgroundColor: Colors.white,
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Icon(Icons.camera_alt, color: Colors.black),
                ),

                // BOTÓN CAMBIAR CÁMARA
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.flip_camera_android,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: _isProcessing ? null : _toggleCamera,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
