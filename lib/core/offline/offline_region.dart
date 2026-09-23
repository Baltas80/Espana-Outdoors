class OfflineRegion {
  const OfflineRegion({
    required this.id,
    required this.name,
    required this.description,
    required this.downloadUrl,
    required this.sizeBytes,
    required this.updatedAt,
    required this.sha256,
  });

  final String id;
  final String name;
  final String description;
  final Uri downloadUrl;
  final int sizeBytes;
  final DateTime updatedAt;
  final String sha256;

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
        updated is! String ||
        checksum is! String) {
      throw const FormatException(
        'Invalid offline region metadata: SHA-256 is mandatory.',
      );
    }

    final downloadUrl = Uri.tryParse(url);
    final updatedAt = DateTime.tryParse(updated);
    if (downloadUrl == null ||
        downloadUrl.scheme != 'https' ||
        updatedAt == null) {
      throw const FormatException('Invalid offline region URL or timestamp.');
    }

    final normalizedChecksum = checksum.trim().toLowerCase();
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(normalizedChecksum)) {
      throw const FormatException('Invalid offline region SHA-256 checksum.');
    }

    final normalizedId = id.trim();
    final normalizedName = name.trim();
    if (normalizedId.isEmpty || normalizedName.isEmpty || size.toInt() <= 0) {
      throw const FormatException('Invalid offline region identity or size.');
    }

    return OfflineRegion(
      id: normalizedId,
      name: normalizedName,
      description: description.trim(),
      downloadUrl: downloadUrl,
      sizeBytes: size.toInt(),
      updatedAt: updatedAt.toUtc(),
      sha256: normalizedChecksum,
    );
  }
}
