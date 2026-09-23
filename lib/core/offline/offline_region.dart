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
    if (id is! String || name is! String || description is! String ||
        url is! String || size is! num || updated is! String) {
      throw const FormatException('Invalid offline region metadata.');
    }
    final downloadUrl = Uri.tryParse(url);
    final updatedAt = DateTime.tryParse(updated);
    if (downloadUrl == null || !downloadUrl.hasScheme || updatedAt == null) {
      throw const FormatException('Invalid offline region URL or timestamp.');
    }
    return OfflineRegion(
      id: id,
      name: name,
      description: description,
      downloadUrl: downloadUrl,
      sizeBytes: size.toInt(),
      updatedAt: updatedAt.toUtc(),
      sha256: json['sha256'] as String?,
    );
  }
}
