import 'navigation_models.dart';

abstract interface class NavigationService {
  Future<void> start(String routeId);
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<NavigationSnapshot> update(NavigationPosition sample);
}
