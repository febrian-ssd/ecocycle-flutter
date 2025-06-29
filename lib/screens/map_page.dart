// lib/screens/map_page.dart - FIXED: Without url_launcher dependency, with zoom controls
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:ecocycle_app/models/dropbox.dart';
import 'package:ecocycle_app/providers/auth_provider.dart';
import 'package:ecocycle_app/services/api_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart'; // For copying coordinates

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
  String _errorMessage = '';
  
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
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) {
        throw Exception('Token tidak tersedia. Silakan login ulang.');
      }

      debugPrint('🔄 Fetching dropboxes...');
      final dropboxesData = await _apiService.getDropboxes(token);
      debugPrint('✅ Received ${dropboxesData.length} dropboxes');
      
      final dropboxes = <Dropbox>[];
      for (var data in dropboxesData) {
        try {
          final dropbox = Dropbox.fromJson(data);
          dropboxes.add(dropbox);
          debugPrint('✅ Parsed dropbox: ${dropbox.locationName}');
        } catch (e) {
          debugPrint('❌ Failed to parse dropbox data: $data, error: $e');
        }
      }
      
      if (mounted) {
        setState(() {
          _dropboxes = dropboxes;
          _isLoading = false;
        });
        _updateMarkers(dropboxes);
        _bounceController.forward();
      }
    } catch (e) {
      debugPrint('❌ Error fetching dropboxes: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal memuat data dropbox: ${e.toString()}';
        });
        _showSnackBar('Gagal memuat lokasi dropbox: ${e.toString()}', isError: true);
      }
    }
  }

  void _updateMarkers(List<Dropbox> dropboxes) {
    final Set<Marker> markers = {};
    
    for (var dropbox in dropboxes) {
      try {
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
      } catch (e) {
        debugPrint('❌ Error creating marker for dropbox ${dropbox.id}: $e');
      }
    }
    
    if (mounted) {
      setState(() {
        _markers = markers;
      });
      debugPrint('✅ Updated ${markers.length} markers on map');
    }
  }

  void _showDropboxDetails(Dropbox dropbox) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildDropboxBottomSheet(dropbox),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: isError ? 5 : 3),
      ),
    );
  }

  // ADDED: Zoom in function
  Future<void> _zoomIn() async {
    final GoogleMapController controller = await _controller.future;
    final currentZoom = await controller.getZoomLevel();
    if (currentZoom < 21) {
      await controller.animateCamera(CameraUpdate.zoomTo(currentZoom + 1));
    }
  }

  // ADDED: Zoom out function
  Future<void> _zoomOut() async {
    final GoogleMapController controller = await _controller.future;
    final currentZoom = await controller.getZoomLevel();
    if (currentZoom > 3) {
      await controller.animateCamera(CameraUpdate.zoomTo(currentZoom - 1));
    }
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
                  // Main content
                  if (_isLoading)
                    _buildLoadingState()
                  else if (_errorMessage.isNotEmpty)
                    _buildErrorState()
                  else
                    _buildMapContainer(),
                  
                  // Floating buttons
                  if (!_isLoading && _errorMessage.isEmpty)
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
              child: const Icon(
                Icons.location_on,
                color: Colors.white,
                size: 24,
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

  Widget _buildLoadingState() {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              'Memuat peta dropbox...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Mohon tunggu sebentar',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'Gagal Memuat Peta',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _errorMessage = '';
                  });
                  _fetchDropboxes();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapContainer() {
    return ScaleTransition(
      scale: _bounceAnimation,
      child: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _kMedan,
        style: _getMapStyle(),
        onMapCreated: (GoogleMapController controller) async {
          try {
            if (!_controller.isCompleted) {
              _controller.complete(controller);
              debugPrint('✅ Map controller completed');
              
              // Auto-fit bounds if there are dropboxes
              if (_dropboxes.isNotEmpty) {
                _fitMapBounds(controller);
              }
            }
          } catch (e) {
            debugPrint('❌ Error completing map controller: $e');
          }
        },
        markers: _markers,
        zoomControlsEnabled: false, // We'll use custom zoom controls
        myLocationButtonEnabled: false,
        compassEnabled: false,
        mapToolbarEnabled: false,
        trafficEnabled: false,
        buildingsEnabled: true,
        onTap: (LatLng position) {
          debugPrint('📍 Map tapped at: ${position.latitude}, ${position.longitude}');
        },
      ),
    );
  }

  String? _getMapStyle() {
    return null; // Use default Google Maps style
  }

  Future<void> _fitMapBounds(GoogleMapController controller) async {
    if (_dropboxes.isEmpty) return;

    try {
      final bounds = _calculateBounds();
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100.0),
      );
    } catch (e) {
      debugPrint('❌ Error fitting map bounds: $e');
    }
  }

  LatLngBounds _calculateBounds() {
    double minLat = _dropboxes.first.latitude;
    double maxLat = _dropboxes.first.latitude;
    double minLng = _dropboxes.first.longitude;
    double maxLng = _dropboxes.first.longitude;

    for (var dropbox in _dropboxes) {
      minLat = minLat < dropbox.latitude ? minLat : dropbox.latitude;
      maxLat = maxLat > dropbox.latitude ? maxLat : dropbox.latitude;
      minLng = minLng < dropbox.longitude ? minLng : dropbox.longitude;
      maxLng = maxLng > dropbox.longitude ? maxLng : dropbox.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  // UPDATED: Added zoom controls
  Widget _buildFloatingButtons() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: Column(
        children: [
          // Zoom In Button
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: FloatingActionButton(
              heroTag: "zoom_in",
              onPressed: _zoomIn,
              backgroundColor: const Color(0xFF4CAF50),
              mini: true,
              elevation: 0,
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(height: 8),
          
          // Zoom Out Button
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: FloatingActionButton(
              heroTag: "zoom_out",
              onPressed: _zoomOut,
              backgroundColor: const Color(0xFF4CAF50),
              mini: true,
              elevation: 0,
              child: const Icon(Icons.remove, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          
          // My Location Button
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FloatingActionButton(
              heroTag: "my_location",
              onPressed: _goToMyLocation,
              backgroundColor: const Color(0xFF4CAF50),
              elevation: 0,
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          
          // Refresh Button
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: FloatingActionButton(
              heroTag: "refresh",
              onPressed: _fetchDropboxes,
              backgroundColor: const Color(0xFF2A2A2A),
              elevation: 0,
              child: const Icon(Icons.refresh, color: Colors.white),
            ),
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
                        onPressed: () => _showNavigationOptions(dropbox),
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
                          if (mounted) {
                            Navigator.pop(context);
                            _centerMapOnDropbox(dropbox);
                          }
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
    try {
      // Check and request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Izin lokasi ditolak', isError: true);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar('Izin lokasi ditolak permanen. Aktifkan di pengaturan.', isError: true);
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final GoogleMapController controller = await _controller.future;
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 16.0,
          ),
        ),
      );

      if (mounted) {
        _showSnackBar('Lokasi Anda ditemukan');
      }
      debugPrint('✅ Moved to user location: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      debugPrint('❌ Error getting location: $e');
      if (mounted) {
        _showSnackBar('Gagal mendapatkan lokasi: ${e.toString()}', isError: true);
      }
    }
  }

  Future<void> _centerMapOnDropbox(Dropbox dropbox) async {
    try {
      final GoogleMapController controller = await _controller.future;
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(dropbox.latitude, dropbox.longitude),
            zoom: 16.0,
          ),
        ),
      );
      debugPrint('✅ Centered map on dropbox: ${dropbox.locationName}');
    } catch (e) {
      debugPrint('❌ Error centering map: $e');
    }
  }

  // UPDATED: Show navigation options without url_launcher
  void _showNavigationOptions(Dropbox dropbox) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.navigation,
                color: Color(0xFF4CAF50),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Navigasi ke ${dropbox.locationName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Koordinat Lokasi:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${dropbox.latitude}, ${dropbox.longitude}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _copyCoordinates(dropbox),
                        icon: const Icon(
                          Icons.copy,
                          color: Color(0xFF4CAF50),
                          size: 20,
                        ),
                        tooltip: 'Salin koordinat',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Salin koordinat di atas dan buka di aplikasi peta favorit Anda seperti Google Maps, Waze, atau yang lainnya.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (mounted) Navigator.pop(context);
            },
            child: const Text(
              'Tutup',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _copyCoordinates(dropbox),
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Salin Koordinat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyCoordinates(Dropbox dropbox) async {
    final coordinates = '${dropbox.latitude}, ${dropbox.longitude}';
    await Clipboard.setData(ClipboardData(text: coordinates));
    
    if (mounted) {
      Navigator.pop(context); // Close dialog
      Navigator.pop(context); // Close bottom sheet
      _showSnackBar('Koordinat berhasil disalin: $coordinates');
    }
  }
}