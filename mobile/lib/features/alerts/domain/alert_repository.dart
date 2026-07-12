import 'earthquake.dart';

abstract interface class AlertRepository {
  Stream<List<Earthquake>> watchCached();

  Future<AlertSnapshot> refresh();

  Future<Earthquake?> getById(String id);
}
