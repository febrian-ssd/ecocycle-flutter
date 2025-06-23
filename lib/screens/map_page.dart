// lib/screens/map_page.dart - Dark Theme Enhanced (FIXED - Removed unused field)
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

class MapPageState extends State<MapPage> with TickerProviderStateMixin {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  final ApiService _apiService = ApiService();
  Set<Marker> _markers = {};
  bool _isLoading = true;
  List<Dropbox> _dropboxes = [];
  // REMOVED: Unused field _selectedDropbox that was causing the warning
  
  late AnimationController _fadeController;
  late AnimationController _bounceController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _bounceAnimation;

  static const CameraPosition _kMedan = CameraPosition(
    target: LatLng(3.595196, 98.672226),
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _initAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDropboxes();
    });
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    
    _bounceAnimation = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut));
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _fetchDropboxes() async {
    if (!mounted) return;

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) {
        return;
      }

      final dropboxesData = await _apiService.getDropboxes(token);
      final dropboxes = dropboxesData.map((data) => Dropbox.fromJson(data)).toList();
      
      if (mounted) {
        setState(() {
          _dropboxes = dropboxes;
        });
        _updateMarkers(dropboxes);
        _bounceController.forward();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load locations: ${e.toString()}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
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
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'EcoCycle Dropbox',
            snippet: dropbox.locationName,
            onTap: () => _showDropboxDetails(dropbox),
          ),
          onTap: () => _showDropboxDetails(dropbox),
        ),
      );
    }
    setState(() {
      _markers = markers;
    });
  }

  void _showDropboxDetails(Dropbox dropbox) {
    // FIXED: No longer setting _selectedDropbox since it was unused
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildDropboxBottomSheet(dropbox),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Stack(
                children: [
                  _isLoading ? _buildLoadingMap() : _buildMap(),
                  if (_isLoading) _buildLoadingOverlay(),
                  _buildFloatingButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF4CAF50)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                'assets/logo.png',
                height: 28,
                width: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'EcoCycle Map',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${_dropboxes.length} Dropbox',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingMap() {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: const Center(
        child: Text(
          'Loading Map...',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMap() {
    return ScaleTransition(
      scale: _bounceAnimation,
      child: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _kMedan,
        style: '''
        [
          {
            "elementType": "geometry",
            "stylers": [{"color": "#1d2c4d"}]
          },
          {
            "elementType": "labels.text.fill",
            "stylers": [{"color": "#8ec3b9"}]
          },
          {
            "elementType": "labels.text.stroke",
            "stylers": [{"color": "#1a3646"}]
          },
          {
            "featureType": "administrative.country",
            "elementType": "geometry.stroke",
            "stylers": [{"color": "#4b6878"}]
          },
          {
            "featureType": "administrative.land_parcel",
            "elementType": "labels.text.fill",
            "stylers": [{"color": "#64779e"}]
          },
          {
            "featureType": "administrative.province",
            "elementType": "geometry.stroke",
            "stylers": [{"color": "#4b6878"}]
          },
          {
            "featureType": "landscape.man_made",
            "elementType": "geometry.stroke",
            "stylers": [{"color": "#334e87"}]
          },
          {
            "featureType": "landscape.natural",
            "elementType": "geometry",
            "stylers": [{"color": "#023e58"}]
          },
          {
            "featureType": "poi",
            "elementType": "geometry",
            "stylers": [{"color": "#283d6a"}]
          },
          {
            "featureType": "poi",
            "elementType": "labels.text.fill",
            "stylers": [{"color": "#6f9ba5"}]
          },
          {
            "featureType": "poi",
            "elementType": "labels.text.stroke",
            "stylers": [{"color": "#1d2c4d"}]
          },
          {
            "featureType": "poi.park",
            "elementType": "geometry.fill",
            "stylers": [{"color": "#023e58"}]
          },
          {
            "featureType": "poi.park",
            "elementType": "labels.text.fill",
            "stylers": [{"color": "#3C7680"}]
          },
          {
            "featureType": "road",
            "elementType": "geometry",
            "stylers": [{"color": "#304a7d"}]
          },
          {
            "featureType": "road",
            "elementType": "labels.text.fill",
            "stylers": [{"color": "#98a5be"}]
          },
          {
            "featureType": "road",
            "elementType": "labels.text.stroke",
            "stylers": [{"color": "#1d2c4d"}]
          },
          {
            "featureType": "road.highway",
            "elementType": "geometry",
            "stylers": [{"color": "#2c6675"}]
          },
          {
            "featureType": "road.highway",
            "elementType": "geometry.stroke",
            "stylers": [{"color": "#255763"}]
          },
          {
            "featureType": "road.highway",
            "elementType": "labels.text.fill",
            "stylers": [{"color": "#b0d5ce"}]
          },
          {
            "featureType": "road.highway",
            "elementType": "labels.text.stroke",
            "stylers": [{"color": "#023e58"}]
          },
          {
            "featureType": "transit",
            "elementType": "labels.text.fill",
            "stylers": [{"color": "#98a5be"}]
          },
          {
            "featureType": "transit",
            "elementType": "labels.text.stroke",
            "stylers": [{"color": "#1d2c4d"}]
          },
          {
            "featureType": "transit.line",
            "elementType": "geometry.fill",
            "stylers": [{"color": "#283d6a"}]
          },
          {
            "featureType": "transit.station",
            "elementType": "geometry",
            "stylers": [{"color": "#3a4762"}]
          },
          {
            "featureType": "water",
            "elementType": "geometry",
            "stylers": [{"color": "#0e1626"}]
          },
          {
            "featureType": "water",
            "elementType": "labels.text.fill",
            "stylers": [{"color": "#4e6d70"}]
          }
        ]
        ''',
        onMapCreated: (GoogleMapController controller) {
          if (!_controller.isCompleted) {
            _controller.complete(controller);
          }
        },
        markers: _markers,
        zoomControlsEnabled: false,
        myLocationButtonEnabled: false,
        compassEnabled: false,
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
              const SizedBox(height: 16),
              Text(
                'Memuat lokasi dropbox...',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingButtons() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: Column(
        children: [
          FloatingActionButton(
            heroTag: "my_location",
            onPressed: _goToMyLocation,
            backgroundColor: const Color(0xFF4CAF50),
            child: const Icon(Icons.my_location, color: Colors.white),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "refresh",
            onPressed: _fetchDropboxes,
            backgroundColor: const Color(0xFF2A2A2A),
            child: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildDropboxBottomSheet(Dropbox dropbox) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.recycling,
                        color: Color(0xFF4CAF50),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'EcoCycle Dropbox',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'ID: ${dropbox.id}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'AKTIF',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Location Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Color(0xFF4CAF50),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Lokasi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dropbox.locationName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Lat: ${dropbox.latitude.toStringAsFixed(6)}, Lng: ${dropbox.longitude.toStringAsFixed(6)}',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToDropbox(dropbox),
                        icon: const Icon(Icons.directions, size: 18),
                        label: const Text(
                          'Arah',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _centerMapOnDropbox(dropbox);
                        },
                        icon: const Icon(Icons.center_focus_strong, size: 18),
                        label: const Text(
                          'Fokus',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4CAF50),
                          side: const BorderSide(color: Color(0xFF4CAF50)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _goToMyLocation() async {
    // This would typically use location services
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(_kMedan),
    );
  }

  Future<void> _centerMapOnDropbox(Dropbox dropbox) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(dropbox.latitude, dropbox.longitude),
          zoom: 16.0,
        ),
      ),
    );
  }

  void _navigateToDropbox(Dropbox dropbox) {
    // This would typically open a navigation app
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Navigasi ke ${dropbox.locationName}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}