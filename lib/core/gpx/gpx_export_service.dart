import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:gpx/gpx.dart';

import 'gpx_import_service.dart';

class GpxExportService {
  const GpxExportService();

  String toGpxString(ImportedTrack track) {
    final gpx = Gpx()
      ..version = '1.1'
      ..creator = 'España Outdoor'
      ..trks = [
        Trk(
          name: track.name,
          trksegs: [
            Trkseg(
              trkpts: List.generate(track.points.length, (index) {
                final point = track.points[index];
                final elevations = track.elevationsMeters;
                final timestamps = track.timestamps;
                return Wpt(
                  lat: point.latitude,
                  lon: point.longitude,
                  ele: elevations != null && index < elevations.length
                      ? elevations[index]
                      : null,
                  time: timestamps != null && index < timestamps.length
                      ? timestamps[index]
                      : null,
                );
              }, growable: false),
            ),
          ],
        ),
      ];

    return GpxWriter().asString(gpx, pretty: true);
  }

  Future<Uri?> saveTrack(ImportedTrack track) {
    final bytes = Uint8List.fromList(utf8.encode(toGpxString(track)));
    return FilePicker.saveFile(
      fileName: _safeFileName(track.name),
      bytes: bytes,
      mimeType: 'application/gpx+xml',
      type: FileType.custom,
      allowedExtensions: ['gpx'],
    );
  }

  String _safeFileName(String name) {
    final normalized = name.trim().isEmpty ? 'ruta' : name.trim();
    final safe = normalized.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    return safe.toLowerCase().endsWith('.gpx') ? safe : '$safe.gpx';
  }
}
