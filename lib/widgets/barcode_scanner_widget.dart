import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Full-screen barcode scanner using [mobile_scanner].
///
/// Displays a real-time camera preview with a scan overlay.
/// Provides a torch toggle and a close button.
/// Calls [onDetected] when a barcode is successfully read.
class BarcodeScannerWidget extends StatefulWidget {
  final void Function(String barcode) onDetected;

  const BarcodeScannerWidget({super.key, required this.onDetected});

  @override
  State<BarcodeScannerWidget> createState() => _BarcodeScannerWidgetState();
}

class _BarcodeScannerWidgetState extends State<BarcodeScannerWidget> {
  MobileScannerController? _controller;
  bool _isTorchOn = false;
  bool _detected = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      torchEnabled: false,
      returnImage: false,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_detected) return; // prevent repeated fires
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    _detected = true;
    widget.onDetected(rawValue);
  }

  void _toggleTorch() {
    _controller?.toggleTorch();
    setState(() => _isTorchOn = !_isTorchOn);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // --- Camera preview ---
          MobileScanner(
            controller: _controller,
            onDetect: _onBarcodeDetected,
          ),

          // --- Scan overlay ---
          Center(
            child: Container(
              width: 280,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.8),
                  width: 3,
                ),
              ),
            ),
          ),

          // --- Instructions at top ---
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 0,
            right: 0,
            child: const Center(
              child: Text(
                'Arahkan kamera ke barcode produk',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          // --- Close button (top-left) ---
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 12,
            child: SafeArea(
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),

          // --- Torch toggle (top-right) ---
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 12,
            child: SafeArea(
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: Icon(
                    _isTorchOn ? Icons.flash_on : Icons.flash_off,
                    color: Colors.white,
                  ),
                  onPressed: _toggleTorch,
                ),
              ),
            ),
          ),

          // --- Bottom bar ---
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Scan barcode otomatis',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
