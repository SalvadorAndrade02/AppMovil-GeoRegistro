import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import 'package:geocoding/geocoding.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/data_overlay.dart';

class PreviewScreen extends StatefulWidget {
  final String imagePath;
  final double lat;
  final double lng;
  final String direccion;

  const PreviewScreen({
    super.key,
    required this.imagePath,
    required this.lat,
    required this.lng,
    required this.direccion,
  });

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  final TextEditingController _notesController = TextEditingController();
  final ScreenshotController _screenshotController = ScreenshotController();
  Offset? _rectPosition; // Guarda la posición (x, y) del cuadro

  bool _isProcessing = false;

  // 1. Declaramos la variable de fecha como parte del estado
  late DateTime _selectedDateTime;
  String _address = "Cargando dirección..."; // Variable de estado

  Widget _buildImageToCapture(String formattedDate) {
    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        // LA IMAGEN
        Container(
          width: 1080,
          child: Image.file(File(widget.imagePath), fit: BoxFit.contain),
        ),
        // ETIQUETA CUADRILLA
        Positioned(
          top: 15,
          right: 15,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: Colors.white24),
            ),
            child: const Text(
              "CUADRILLA 7",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ),
        // LOS DATOS
        Padding(
          padding: const EdgeInsets.all(40.0),
          child: DataOverlay(
            lat: widget.lat,
            lng: widget.lng,
            date: formattedDate,
            notes: _notesController.text,
            address: _address,
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    // Inicializamos con la fecha y hora actual
    _selectedDateTime = DateTime.now();
    _getAddressFromLatLng(); // La llamamos al iniciar la pantalla
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // 2. Función para abrir los selectores de Fecha y Hora
  Future<void> _pickDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;

    if (!mounted) return;
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );

    if (pickedTime == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  //Función para guardar la imagen en la galería
  Future<void> _handleSave() async {
    print("--- DEBUG: BOTÓN PRESIONADO ---");

    // 1. Cerramos el teclado para evitar interferencias en el layout
    FocusScope.of(context).unfocus();

    setState(() => _isProcessing = true);

    try {
      // Formateamos la fecha para que el widget en memoria sea igual al de la pantalla
      String formattedDate = DateFormat(
        'dd/MM/yyyy - HH:mm',
      ).format(_selectedDateTime);

      print("--- DEBUG: GENERANDO CAPTURA DESDE WIDGET... ---");

      // 2. Usamos captureFromWidget: Esto crea la imagen "en privado" sin importar el scroll o el teclado
      final capturedImage = await _screenshotController.captureFromWidget(
        Stack(
          alignment: Alignment.bottomLeft,
          children: [
            // 1. LA IMAGEN (Base)
            Container(
              width: 1080,
              child: Image.file(File(widget.imagePath), fit: BoxFit.contain),
            ),

            // 2. ETIQUETA CUADRILLA (Ahora encima de la imagen)
            Positioned(
              top: 15,
              right: 15,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Text(
                  "CUADRILLA 7",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),

            // 3. TU OVERLAY DE DATOS
            Padding(
              padding: const EdgeInsets.all(40.0),
              child: DataOverlay(
                lat: widget.lat,
                lng: widget.lng,
                date: formattedDate,
                notes: _notesController.text,
                address: _address,
              ),
            ),
          ],
        ),
        delay: const Duration(milliseconds: 200),
        pixelRatio: 1.0,
      );

      if (capturedImage != null) {
        print("--- DEBUG: ¡IMAGEN GENERADA! GUARDANDO EN DISCO... ---");

        // 3. Guardado físico en la galería
        await Gal.putImageBytes(capturedImage);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ ¡Imagen guardada en tu galería!'),
              backgroundColor: Colors.green,
            ),
          );
          // Volver a la cámara
          await Future.delayed(const Duration(seconds: 1));
          Navigator.pop(context);
        }
      } else {
        print("--- DEBUG: LA GENERACIÓN SIGUE DANDO NULL ---");
      }
    } catch (e) {
      print("--- DEBUG: ERROR CRÍTICO: $e ---");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  //Funcion para compartir
  Future<void> _handleShare() async {
    setState(() => _isProcessing = true);
    try {
      String formattedDate = DateFormat(
        'dd/MM/yyyy - HH:mm',
      ).format(_selectedDateTime);

      final capturedImage = await _screenshotController.captureFromWidget(
        _buildImageToCapture(formattedDate),
        delay: const Duration(milliseconds: 200),
      );

      if (capturedImage != null) {
        String caption =
            "📍 Registro: $_address\n"
            "📝 Notas: ${_notesController.text}\n";

        await Share.shareXFiles([
          XFile.fromData(
            capturedImage,
            name: 'registro_campo.png',
            mimeType: 'image/png',
          ),
        ], text: caption);
      }
    } catch (e) {
      print("Error al compartir: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _getAddressFromLatLng() async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        widget.lat,
        widget.lng,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _address = "${place.street}, ${place.subLocality}, ${place.locality}";
        });
      }
    } catch (e) {
      setState(() {
        _address = "Dirección no disponible";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Formateamos la fecha seleccionada para mostrarla en el Overlay y el botón
    String formattedDate = DateFormat(
      'dd/MM/yyyy - HH:mm',
    ).format(_selectedDateTime);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Detalles del Registro",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _isProcessing ? null : _handleShare,
          ),
        ],
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Screenshot(
                    controller: _screenshotController,
                    child: Stack(
                      alignment: Alignment.bottomLeft,
                      children: [
                        // 1. LA IMAGEN BASE
                        Image.file(
                          File(widget.imagePath),
                          width: double.infinity,
                          fit: BoxFit.contain,
                        ),

                        // 2. NUEVA ETIQUETA: CUADRILLA 7
                        Positioned(
                          top: 15,
                          right: 15,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(
                                0.6,
                              ), // Fondo oscuro para que resalte
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Text(
                              "CUADRILLA 7",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        ),

                        // 3. TU OVERLAY DE DATOS (EL QUE YA TENÍAS)
                        Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: DataOverlay(
                            lat: widget.lat,
                            lng: widget.lng,
                            date: formattedDate,
                            notes: _notesController.text,
                            address: _address,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 3. NUEVO: Botón para editar Fecha y Hora
                        InkWell(
                          onTap: _pickDateTime,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.blueAccent.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_month,
                                  color: Colors.blueAccent,
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "FECHA Y HORA DEL REGISTRO",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueAccent,
                                      ),
                                    ),
                                    Text(
                                      formattedDate,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                const Icon(
                                  Icons.edit,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Row(
                          children: [
                            Icon(Icons.edit_note, color: Colors.blueGrey),
                            SizedBox(width: 8),
                            Text(
                              "OBSERVACIONES DE CAMPO",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _notesController,
                          maxLines: 4,
                          onChanged: (value) {
                            setState(() {});
                          },
                          decoration: InputDecoration(
                            hintText: "Escribe aquí detalles adicionales...",
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton.icon(
                            onPressed: _handleSave,
                            icon: const Icon(Icons.cloud_done_rounded),
                            label: const Text(
                              "GUARDAR REGISTRO",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Center(
                          child: Text(
                            "La imagen se guardará con los datos impresos.",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
