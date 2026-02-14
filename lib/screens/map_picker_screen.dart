import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? selectedLocation;
  String selectedAddress = "";
  late MapController mapController;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _moveToCurrentLocation();
  }

  Future<void> _moveToCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission required')),
          );
        }
        setState(() => isLoading = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      if (mounted) {
        final latLng = LatLng(position.latitude, position.longitude);
        mapController.move(latLng, 15);
        setState(() {
          selectedLocation = latLng;
          isLoading = false;
        });
        await _getAddress(latLng);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _getAddress(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address =
            "${place.street ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}"
                .replaceAll(", , ", ", ")
                .replaceAll(", ,", "");

        setState(() {
          selectedAddress =
              address.isEmpty ? "Unknown Location" : address;
        });
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pick Location"),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: const LatLng(20.5937, 78.9629),
              initialZoom: 5,
              onTap: (tapPosition, point) async {
                setState(() {
                  selectedLocation = point;
                });
                await _getAddress(point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.example.save_bite',
              ),
              if (selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: selectedLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_pin,
                        size: 40,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
            ),
          if (selectedLocation != null && !isLoading)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Selected Location",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        selectedAddress.isNotEmpty
                            ? selectedAddress
                            : "Lat: ${selectedLocation!.latitude.toStringAsFixed(4)}, Lng: ${selectedLocation!.longitude.toStringAsFixed(4)}",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                          ),
                          onPressed: () {
                            Navigator.pop(context, {
                              "latitude": selectedLocation!.latitude,
                              "longitude": selectedLocation!.longitude,
                              "address": selectedAddress,
                            });
                          },
                          child: const Text("Confirm Location"),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }
}
