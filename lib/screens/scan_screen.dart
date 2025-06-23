// lib/screens/scan_screen.dart - Enhanced Dropbox Scan
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ecocycle_app/screens/konfirmasi_scan_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin {
  bool _isScanCompleted = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleDetection(String code) {
    if (!_isScanCompleted) {
      setState(() {
        _isScanCompleted = true;
      });
      
      // Haptic feedback
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => 
              KonfirmasiScanScreen(qrCodeJsonData: code),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ).then((_) {
        if (mounted) {
          setState(() {
            _isScanCompleted = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'Scan QR Dropbox',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            onDetect: (capture) {
              if (capture.barcodes.isNotEmpty) {
                final String code = capture.barcodes.first.rawValue ?? "Error";
                _handleDetection(code);
              }
            },
          ),
          
          // Overlay dengan scanning frame
          Center(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF4CAF50),
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
                      children: [
                        // Corner indicators
                        Positioned(
                          top: -2,
                          left: -2,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(18),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(18),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -2,
                          left: -2,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(18),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              borderRadius: const BorderRadius.only(
                                bottomRight: Radius.circular(18),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Instructions
          Positioned(
            top: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    color: Color(0xFF4CAF50),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Arahkan kamera ke QR Code Dropbox',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pastikan QR Code berada di dalam frame',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Test button (for demo)
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // Simulasi scan dengan data dropbox yang lebih realistis
                      final fakeDropboxData = '''
                      {
                        "type": "dropbox_scan",
                        "dropbox_id": "DB001",
                        "location": "Medan Plaza",
                        "address": "Jl. Guru Patimpus No.1",
                        "waste_types": ["plastic", "paper", "metal"],
                        "coordinates": {
                          "lat": 3.5952,
                          "lng": 98.6722
                        },
                        "scan_time": "${DateTime.now().toIso8601String()}"
                      }
                      ''';
                      _handleDetection(fakeDropboxData);
                    },
                    icon: const Icon(Icons.science, color: Colors.white),
                    label: const Text(
                      'Demo Scan Dropbox',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gunakan untuk testing scan dropbox',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// lib/screens/konfirmasi_scan_screen.dart - Enhanced Confirmation
class KonfirmasiScanScreen extends StatefulWidget {
  final String qrCodeJsonData;
  
  const KonfirmasiScanScreen({super.key, required this.qrCodeJsonData});

  @override
  State<KonfirmasiScanScreen> createState() => _KonfirmasiScanScreenState();
}

class _KonfirmasiScanScreenState extends State<KonfirmasiScanScreen> 
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  // Dropbox info
  String _dropboxId = '';
  String _location = '';
  String _address = '';
  List<String> _wasteTypes = [];
  
  // Scan data
  String _selectedWasteType = '';
  double _weight = 0.0;
  int _potentialCoins = 0;
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _parseDropboxData();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _parseDropboxData() {
    try {
      final data = json.decode(widget.qrCodeJsonData);
      setState(() {
        _dropboxId = data['dropbox_id'] ?? data['id'] ?? 'Unknown';
        _location = data['location'] ?? 'Unknown Location';
        _address = data['address'] ?? '';
        
        if (data['waste_types'] != null) {
          _wasteTypes = List<String>.from(data['waste_types']);
          if (_wasteTypes.isNotEmpty) {
            _selectedWasteType = _wasteTypes.first;
          }
        } else {
          _wasteTypes = ['plastic', 'paper', 'metal', 'glass'];
          _selectedWasteType = 'plastic';
        }
        
        // Set default weight
        _weight = 50.0; // Default 50 gram
        _calculateCoins();
      });
    } catch (e) {
      debugPrint('Error parsing dropbox data: $e');
      // Fallback data
      setState(() {
        _dropboxId = 'DB001';
        _location = 'Demo Dropbox';
        _address = 'Demo Location';
        _wasteTypes = ['plastic', 'paper', 'metal', 'glass'];
        _selectedWasteType = 'plastic';
        _weight = 50.0;
        _calculateCoins();
      });
    }
  }

  void _calculateCoins() {
    // Hitung koin berdasarkan jenis sampah dan berat
    int multiplier;
    switch (_selectedWasteType.toLowerCase()) {
      case 'plastic':
        multiplier = 2; // 2 koin per gram
        break;
      case 'paper':
        multiplier = 1; // 1 koin per gram
        break;
      case 'metal':
        multiplier = 5; // 5 koin per gram
        break;
      case 'glass':
        multiplier = 3; // 3 koin per gram
        break;
      default:
        multiplier = 1;
    }
    
    setState(() {
      _potentialCoins = (_weight * multiplier).floor();
    });
  }

  Future<void> _confirmScan() async {
    if (_selectedWasteType.isEmpty || _weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Pilih jenis sampah dan masukkan berat',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.orange[700],
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception('Not authenticated');

      await _apiService.confirmScan(
        token,
        dropboxCode: _dropboxId,
        wasteType: _selectedWasteType,
        weight: _weight,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => 
                TransaksiBerhasilScreen(
                  title: 'Scan Berhasil!',
                  subtitle: 'Anda mendapat $_potentialCoins EcoCoins',
                  coins: _potentialCoins,
                ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Scan gagal: ${e.toString()}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'Konfirmasi Scan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDropboxInfo(),
                const SizedBox(height: 24),
                _buildWasteTypeSelector(),
                const SizedBox(height: 24),
                _buildWeightInput(),
                const SizedBox(height: 24),
                _buildRewardPreview(),
                const SizedBox(height: 32),
                _buildConfirmButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropboxInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4CAF50), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Color(0xFF4CAF50),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Informasi Dropbox',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('ID Dropbox', _dropboxId),
          _buildInfoRow('Lokasi', _location),
          if (_address.isNotEmpty) _buildInfoRow('Alamat', _address),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(color: Colors.grey),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWasteTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih Jenis Sampah',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _wasteTypes.map((type) => _buildWasteTypeChip(type)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWasteTypeChip(String type) {
    final isSelected = _selectedWasteType == type;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedWasteType = type;
          _calculateCoins();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4CAF50) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[600]!,
          ),
        ),
        child: Text(
          type.toUpperCase(),
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[300],
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildWeightInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Berat Sampah (gram)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _weight,
                  min: 1,
                  max: 1000,
                  divisions: 999,
                  activeColor: const Color(0xFF4CAF50),
                  inactiveColor: Colors.grey[600],
                  onChanged: (value) {
                    setState(() {
                      _weight = value;
                      _calculateCoins();
                    });
                  },
                ),
              ),
              Container(
                width: 80,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_weight.toInt()}g',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRewardPreview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4CAF50).withValues(alpha: 0.2),
            const Color(0xFF2E7D32).withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4CAF50)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.eco,
            color: Color(0xFF4CAF50),
            size: 32,
          ),
          const SizedBox(height: 8),
          const Text(
            'Reward yang Akan Diterima',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_potentialCoins EcoCoins',
            style: const TextStyle(
              color: Color(0xFF4CAF50),
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Setara dengan ${ConversionUtils.formatCurrency(_potentialCoins * 100)}',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _confirmScan,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          disabledBackgroundColor: Colors.grey[700],
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Konfirmasi Scan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}