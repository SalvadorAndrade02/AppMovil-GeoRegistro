import 'package:geolocator/geolocator.dart';

class LocationService {
  // Esta función nos dará la latitud y longitud exacta
  static Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('El GPS está desactivado.');

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return Future.error('Permiso denegado.');
    }
    
    // Alta precisión es clave para lo que buscas
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high 
    );
  }
}