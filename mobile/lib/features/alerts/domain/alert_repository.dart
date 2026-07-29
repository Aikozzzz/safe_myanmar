import 'earthquake.dart';

abstract interface class AlertRepository {
  Stream<List<Earthquake>> watchCached();

  Future<AlertSnapshot> refresh();

  Future<Earthquake?> getById(String id);
}

abstract interface class CachedAlertRepository implements AlertRepository {
  Stream<AlertSnapshot?> watchCachedSnapshot();
}
