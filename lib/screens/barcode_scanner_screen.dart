import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/product.dart';

/// Result returned from the barcode scanner.
///
/// [product] is non-null when a matching product was found.
/// [barcode] is always the scanned barcode value.
class BarcodeScanResult {
  final String barcode;
  final Product? product;

  const BarcodeScanResult({required this.barcode, this.product});
}

/// Full-screen barcode scanner that uses the device camera.
///
/// Accepts a list of [products] to match scanned barcodes against.
/// Returns a [BarcodeScanResult] via Navigator.pop.
class BarcodeScannerScreen extends StatefulWidget {
  final List<Product> products;

  const BarcodeScannerScreen({super.key, required this.products});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  MobileScannerController? _scannerController;
  bool _isProcessing = false;
  bool _cameraAvailable = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    _isProcessing = true;
    final code = barcode.rawValue!;

    // Vibrate/haptic feedback
    HapticFeedback.heavyClick();

    // Search product by exact barcode match
    final product = widget.products.cast<Product?>().firstWhere(
          (p) => p!.barcode == code,
          orElse: () => null,
        );

    if (product != null) {
      // Product found → return it
      Navigator.pop(
        context,
        BarcodeScanResult(barcode: code, product: product),
      );
    } else {
      // Product not found → show error, allow retry
      setState(() {
        _errorMessage = 'Produk dengan barcode "$code" tidak ditemukan';
        _isProcessing = false;
      });
    }
  }

  void _onScannerError(Object error, Widget? widget) {
    setState(() {
      _cameraAvailable = false;
      _errorMessage = 'Kamera tidak tersedia: $error';
    });
  }

  Future<void> _requestCameraPermission() async {
    try {
      // MobileScanner handles permission requests internally.
      // If permission was denied, we show the dialog and then retry.
      await _scannerController?.stop();
      await _scannerController?.start();
      setState(() {
        _cameraAvailable = true;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Izin kamera ditolak';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pindai Barcode'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Torch toggle
          IconButton(
            icon: const Icon(Icons.flashlight_on),
            onPressed: () => _scannerController?.toggleTorch(),
            tooltip: 'Nyalakan senter',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview or error state
          if (_cameraAvailable)
            MobileScanner(
              controller: _scannerController,
              onDetect: _onBarcodeDetected,
              errorBuilder: (context, error, child) {
                // Camera unavailable
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _onScannerError(error, child);
                });
                return _buildCameraUnavailable(theme);
              },
            )
          else
            _buildCameraUnavailable(theme),

          // Scan overlay guide
          if (_cameraAvailable && _errorMessage == null)
            _buildScanOverlay(theme),

          // Error / status overlay
          if (_errorMessage != null) _buildErrorOverlay(theme),

          // Processing indicator
          if (_isProcessing)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(theme),
    );
  }

  Widget _buildScanOverlay(ThemeData theme) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.primary,
              width: 3,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.qr_code_scanner,
                size: 48,
                color: theme.colorScheme.primary.withOpacity(0.3),
              ),
              const SizedBox(height: 8),
              Text(
                'Arahkan ke barcode produk',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  backgroundColor: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraUnavailable(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 80,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Kamera tidak tersedia',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Gunakan input manual untuk mencari produk via barcode',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.keyboard),
              label: const Text('Input Manual'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorOverlay(ThemeData theme) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.black87,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: Colors.orange[300]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                    _isProcessing = false;
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Manual input fallback
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.edit),
              label: const Text('Input Manual'),
            ),
            // Product count
            Text(
              '${widget.products.length} produk tersedia',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
