import 'package:flutter_test/flutter_test.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:mobile/features/navigation/presentation/navigation_map.dart';

void main() {
  test('only a style failure replaces the map with the retry fallback', () {
    expect(isFatalMapLoadError(MapLoadErrorType.STYLE), isTrue);
    expect(isFatalMapLoadError(MapLoadErrorType.TILE), isFalse);
    expect(isFatalMapLoadError(MapLoadErrorType.SOURCE), isFalse);
    expect(isFatalMapLoadError(MapLoadErrorType.SPRITE), isFalse);
    expect(isFatalMapLoadError(MapLoadErrorType.GLYPHS), isFalse);
  });
}
