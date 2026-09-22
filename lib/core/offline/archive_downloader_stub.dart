import 'archive_models.dart';

class PlatformOfflineArchiveDownloader implements OfflineArchiveDownloader {
  @override
  Stream<OfflineArchiveProgress> download(OfflineArchiveSource source) async* {
    throw UnsupportedError(
      'La descarga de archivos offline no está disponible en esta plataforma.',
    );
  }

  @override
  Future<bool> verify(OfflineArchiveSource source) async => false;
}
