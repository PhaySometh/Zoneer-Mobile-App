import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// Holds the LatLng that the map should animate to.
/// Set after a successful property upload, then reset to null.
class MapFocusNotifier extends Notifier<LatLng?> {
  @override
  LatLng? build() => null;

  void focus(LatLng latLng) => state = latLng;

  void clear() => state = null;
}

final mapFocusProvider =
    NotifierProvider<MapFocusNotifier, LatLng?>(MapFocusNotifier.new);
