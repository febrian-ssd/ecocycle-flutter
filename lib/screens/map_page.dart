// lib/screens/map_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:ecocycle_app/models/dropbox.dart';
import 'package:ecocycle_app/providers/auth_provider.dart';
import 'package:ecocycle_app/services/api_service.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  final ApiService _apiService = ApiService();
  Set<Marker> _markers = {};
  bool _isLoading = true;

  static const CameraPosition _kMedan = CameraPosition(
    target: LatLng(3.595196, 98.672226),
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    // Gunakan addPostFrameCallback untuk memastikan context sudah siap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDropboxes();
    });
  }

  Future<void> _fetchDropboxes() async {
    // Pastikan widget masih ada di tree sebelum melanjutkan
    if (!mounted) return;

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) {
        // Jika token tidak ada, mungkin logout paksa atau sesi habis
        // Di sini bisa ditambahkan logika untuk kembali ke login
        return;
      }

      final dropboxes = await _apiService.getDropboxes(token);
      if (mounted) {
        _updateMarkers(dropboxes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load locations: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _updateMarkers(List<Dropbox> dropboxes) {
    final Set<Marker> markers = {};
    for (var dropbox in dropboxes) {
      markers.add(
        Marker(
          markerId: MarkerId(dropbox.id.toString()),
          position: LatLng(dropbox.latitude, dropbox.longitude),
          infoWindow: InfoWindow(
            title: 'DROPBOX',
            snippet: dropbox.locationName,
          ),
        ),
      );
    }
    setState(() {
      _markers = markers;
    });
  }

  // WIDGET BARU UNTUK HEADER
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      color: const Color(0xFF004d00), // Warna hijau header
      child: SafeArea(
        bottom: false, // Tidak perlu padding bawah di SafeArea untuk header
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png', // Pastikan logo ada di folder assets
              height: 35,
            ),
            const SizedBox(width: 10),
            const Text(
              'EcoCycle',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Tampilkan header di sini
          _buildHeader(),

          // Peta akan mengisi sisa ruang yang tersedia
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: _kMedan,
                    onMapCreated: (GoogleMapController controller) {
                      if (!_controller.isCompleted) {
                        _controller.complete(controller);
                      }
                    },
                    markers: _markers,
                  ),
          ),
        ],
      ),
    );
  }
}