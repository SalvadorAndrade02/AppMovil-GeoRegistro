import 'package:flutter/material.dart';

class DataOverlay extends StatelessWidget {
  final double lat;
  final double lng;
  final String date;
  final String notes;
  final String address;

  const DataOverlay({
    super.key,
    required this.lat,
    required this.lng,
    required this.date,
    required this.notes,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FILA DE DIRECCIÓN
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map, color: Colors.orangeAccent, size: 14),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  address.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // FILA DE GPS
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, color: Colors.redAccent, size: 14),
              const SizedBox(width: 4),
              Text(
                "LAT: ${lat.toStringAsFixed(6)} | LNG: ${lng.toStringAsFixed(6)}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // FILA DE FECHA
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today,
                color: Colors.blueAccent,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                date,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),

          // NUEVA SECCIÓN DE OBSERVACIONES
          if (notes.isNotEmpty) ...[
            const Divider(
              color: Colors.white24,
              height: 10,
            ), // Una línea sutil divisoria
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.edit_note,
                  color: Colors.greenAccent,
                  size: 16,
                ),
                const SizedBox(width: 4),
                // Flexible para que si el texto es muy largo, no se salga de la foto
                Flexible(
                  child: Text(
                    notes,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
