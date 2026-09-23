class OfflineRegion {
  const OfflineRegion({
    required this.id,
    required this.name,
    required this.description,
    required this.downloadUrl,
    required this.sizeBytes,
    required this.updatedAt,
    this.sha256,
  });

  final String id;
  final String name;
  final String description;
  final Uri downloadUrl;
  final int sizeBytes;
  final DateTime updatedAt;
  final String? sha256;

  factory OfflineRegion.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final name = json['name'];
    final description = json['description'];
    final url = json['downloadUrl'];
    final size = json['sizeBytes'];
    final updated = json['updatedAt'];
    final checksum = json['sha256'];

    if (id is! String ||
        name is! String ||
        description is! String ||
        url is! String ||
        size is! num ||
        updated is! String) {
      throw const FormatException('Invalid offline region metadata.');
    }

    final downloadUrl = Uri.tryParse(url);
    final updatedAt = DateTime.tryParse(updated);
    if (downloadUrl == null || !downloadUrl.hasScheme || updatedAt == null) {
      throw const FormatException('Invalid offline region URL or timestamp.');
    }

    String? normalizedChecksum;
    if (checksum != null) {
      if (checksum is! String ||
          !RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(checksum.trim())) {
        throw const FormatException('Invalid offline region SHA-256 checksum.');
      }
      normalizedChecksum = checksum.trim().toLowerCase();
    }

    return OfflineRegion(
      id: id,
      name: name,
      description: description,
      downloadUrl: downloadUrl,
      sizeBytes: size.toInt(),
      updatedAt: updatedAt.toUtc(),
      sha256: normalizedChecksum,
    );
  }
}