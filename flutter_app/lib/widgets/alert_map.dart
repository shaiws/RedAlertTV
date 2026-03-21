import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/alert.dart';
import '../models/city_coordinates.dart';
import '../l10n/strings.dart';

/// Displays a Google Map with markers for all cities in the current alert.
class AlertMap extends StatefulWidget {
  final Alert? alert;
  final AppStrings strings;

  const AlertMap({super.key, required this.alert, required this.strings});

  @override
  State<AlertMap> createState() => _AlertMapState();
}

class _AlertMapState extends State<AlertMap> {
  GoogleMapController? _mapController;

  /// Approximate center of Israel
  static const _israelCenter = LatLng(31.5, 34.75);
  static const _israelZoom = 7.5;

  Set<Marker> _buildMarkers() {
    if (widget.alert == null) return {};

    final markers = <Marker>{};
    for (final city in widget.alert!.data) {
      final coords =
          coordinatesForCity(city) ?? fuzzyCoordinatesForCity(city);
      if (coords != null) {
        markers.add(
          Marker(
            markerId: MarkerId(city),
            position: coords,
            infoWindow: InfoWindow(title: city),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              widget.alert!.isTest
                  ? BitmapDescriptor.hueOrange
                  : BitmapDescriptor.hueRed,
            ),
          ),
        );
      }
    }
    return markers;
  }

  void _fitMarkersInView(Set<Marker> markers) {
    if (_mapController == null || markers.isEmpty) return;
    if (markers.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(markers.first.position, 10),
      );
      return;
    }

    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (final m in markers) {
      if (m.position.latitude < minLat) minLat = m.position.latitude;
      if (m.position.latitude > maxLat) maxLat = m.position.latitude;
      if (m.position.longitude < minLng) minLng = m.position.longitude;
      if (m.position.longitude > maxLng) maxLng = m.position.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - 0.2, minLng - 0.2),
          northeast: LatLng(maxLat + 0.2, maxLng + 0.2),
        ),
        48,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant AlertMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.alert != widget.alert) {
      final markers = _buildMarkers();
      _fitMarkersInView(markers);
    }
  }

  @override
  Widget build(BuildContext context) {
    final markers = _buildMarkers();
    final hasAlerts = widget.alert != null && markers.isNotEmpty;

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: _israelCenter,
            zoom: _israelZoom,
          ),
          markers: markers,
          mapType: MapType.normal,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: true,
          onMapCreated: (controller) {
            _mapController = controller;
            if (hasAlerts) _fitMarkersInView(markers);
          },
        ),
        if (!hasAlerts)
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.strings.noActiveAlerts,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
        if (hasAlerts)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.85),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${widget.strings.affectedAreas}: ${widget.alert!.data.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
