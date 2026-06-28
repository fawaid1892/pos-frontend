import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/receipt_settings_provider.dart';
import '../models/receipt_settings.dart';
import '../utils/responsive.dart';

class ReceiptSettingsScreen extends StatefulWidget {
  const ReceiptSettingsScreen({super.key});

  @override
  State<ReceiptSettingsScreen> createState() => _ReceiptSettingsScreenState();
}

class _ReceiptSettingsScreenState extends State<ReceiptSettingsScreen> {
  late TextEditingController _storeNameCtrl;
  late TextEditingController _storeAddressCtrl;
  late TextEditingController _storePhoneCtrl;
  late TextEditingController _headerCtrl;
  late TextEditingController _footerCtrl;
  bool _showPreview = true;

  @override
  void initState() {
    super.initState();
    final settings = context.read<ReceiptSettingsProvider>().settings;
    _storeNameCtrl = TextEditingController(text: settings.storeName);
    _storeAddressCtrl = TextEditingController(text: settings.storeAddress);
    _storePhoneCtrl = TextEditingController(text: settings.storePhone);
    _headerCtrl = TextEditingController(text: settings.headerText);
    _footerCtrl = TextEditingController(text: settings.footerText);
  }

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    _storeAddressCtrl.dispose();
    _storePhoneCtrl.dispose();
    _headerCtrl.dispose();
    _footerCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAll() async {
    final prov = context.read<ReceiptSettingsProvider>();
    final updated = prov.settings.copyWith(
      storeName: _storeNameCtrl.text.trim(),
      storeAddress: _storeAddressCtrl.text.trim(),
      storePhone: _storePhoneCtrl.text.trim(),
      headerText: _headerCtrl.text.trim(),
      footerText: _footerCtrl.text.trim(),
    );
    await prov.updateSettings(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengaturan struk tersimpan'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ReceiptSettingsProvider>();
    final settings = prov.settings;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = context.isTablet;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Struk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Reset ke Default',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Reset Pengaturan'),
                  content: const Text(
                      'Kembalikan semua pengaturan struk ke default?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Batal')),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Reset')),
                  ],
                ),
              );
              if (confirmed == true && mounted) {
                await prov.resetToDefaults();
                setState(() {
                  _storeNameCtrl.text = prov.settings.storeName;
                  _storeAddressCtrl.text = prov.settings.storeAddress;
                  _storePhoneCtrl.text = prov.settings.storePhone;
                  _headerCtrl.text = prov.settings.headerText;
                  _footerCtrl.text = prov.settings.footerText;
                });
              }
            },
          ),
          IconButton(
            icon: Icon(_showPreview ? Icons.edit : Icons.visibility),
            tooltip: _showPreview ? 'Edit' : 'Preview',
            onPressed: () => setState(() => _showPreview = !_showPreview),
          ),
        ],
      ),
      body: isTablet
          ? _buildTabletLayout(settings, colorScheme)
          : _buildMobileLayout(settings, colorScheme),
    );
  }

  Widget _buildTabletLayout(ReceiptSettings settings, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildSettingsForm(settings, colorScheme),
          ),
        ),
        VerticalDivider(width: 1, color: colorScheme.outlineVariant),
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildReceiptPreview(settings, colorScheme),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(ReceiptSettings settings, ColorScheme colorScheme) {
    if (_showPreview) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildReceiptPreview(settings, colorScheme),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => setState(() => _showPreview = false),
              icon: const Icon(Icons.edit),
              label: const Text('Edit Pengaturan'),
            ),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSettingsForm(settings, colorScheme),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => setState(() => _showPreview = true),
            icon: const Icon(Icons.visibility),
            label: const Text('Lihat Preview'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsForm(ReceiptSettings settings, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Informasi Toko',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextField(
          controller: _storeNameCtrl,
          decoration: const InputDecoration(
            labelText: 'Nama Toko',
            prefixIcon: Icon(Icons.store),
          ),
          onChanged: (v) =>
              prov.updateField('storeName', v.trim()),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _storeAddressCtrl,
          decoration: const InputDecoration(
            labelText: 'Alamat Toko',
            prefixIcon: Icon(Icons.location_on),
          ),
          maxLines: 2,
          onChanged: (v) =>
              prov.updateField('storeAddress', v.trim()),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _storePhoneCtrl,
          decoration: const InputDecoration(
            labelText: 'Telepon',
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
          onChanged: (v) =>
              prov.updateField('storePhone', v.trim()),
        ),
        const SizedBox(height: 20),
        const Divider(),
        Text('Header & Footer',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextField(
          controller: _headerCtrl,
          decoration: const InputDecoration(
            labelText: 'Teks Header',
            hintText: 'Terima Kasih telah berbelanja',
            prefixIcon: Icon(Icons.pageview),
          ),
          maxLines: 2,
          onChanged: (v) =>
              prov.updateField('headerText', v.trim()),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _footerCtrl,
          decoration: const InputDecoration(
            labelText: 'Teks Footer',
            hintText: 'Barang yang sudah dibeli tidak dapat dikembalikan',
            prefixIcon: Icon(Icons.pageview),
          ),
          maxLines: 2,
          onChanged: (v) =>
              prov.updateField('footerText', v.trim()),
        ),
        const SizedBox(height: 20),
        const Divider(),
        Text('Tampilan',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        // Font size slider
        Row(
          children: [
            const Icon(Icons.text_fields, size: 20),
            const SizedBox(width: 8),
            const Text('Ukuran Font: '),
            Expanded(
              child: Slider(
                value: settings.fontSize,
                min: 0.5,
                max: 2.0,
                divisions: 6,
                label: '${settings.fontSize.toStringAsFixed(1)}x',
                onChanged: (v) => prov.updateField('fontSize', v),
              ),
            ),
            SizedBox(
              width: 40,
              child: Text(
                '${settings.fontSize.toStringAsFixed(1)}x',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Paper size
        DropdownButtonFormField<String>(
          value: settings.paperSize,
          decoration: const InputDecoration(
            labelText: 'Ukuran Kertas',
            prefixIcon: Icon(Icons.description),
          ),
          items: const [
            DropdownMenuItem(value: '58mm', child: Text('58 mm (StruK)')),
            DropdownMenuItem(value: '80mm', child: Text('80 mm (A4)')),
          ],
          onChanged: (v) {
            if (v != null) prov.updateField('paperSize', v);
          },
        ),
        const SizedBox(height: 16),

        // Toggle options
        SwitchListTile(
          title: const Text('Tampilkan Logo'),
          subtitle: const Text('Logo toko di bagian atas struk'),
          value: settings.showLogo,
          onChanged: (v) => prov.updateField('showLogo', v),
          secondary: const Icon(Icons.image),
        ),
        SwitchListTile(
          title: const Text('Tampilkan Barcode Item'),
          subtitle: const Text('Kode barcode di setiap item struk'),
          value: settings.showItemBarcode,
          onChanged: (v) => prov.updateField('showItemBarcode', v),
          secondary: const Icon(Icons.qr_code),
        ),
        SwitchListTile(
          title: const Text('Tampilkan Nama Kasir'),
          subtitle: const Text('Informasi kasir di struk'),
          value: settings.showCashierName,
          onChanged: (v) => prov.updateField('showCashierName', v),
          secondary: const Icon(Icons.person),
        ),
        SwitchListTile(
          title: const Text('Tampilkan Info Pajak'),
          subtitle: const Text('Rincian pajak di struk'),
          value: settings.showTaxInfo,
          onChanged: (v) => prov.updateField('showTaxInfo', v),
          secondary: const Icon(Icons.receipt),
        ),

        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _saveAll,
          icon: const Icon(Icons.save),
          label: const Text('Simpan Pengaturan', style: TextStyle(fontSize: 16)),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptPreview(ReceiptSettings settings, ColorScheme colorScheme) {
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey.shade900 : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.visibility, size: 20, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Preview Struk',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // --- Receipt Header ---
              if (settings.showLogo)
                Icon(Icons.store, size: 32, color: colorScheme.primary),
              Text(
                settings.storeName,
                style: TextStyle(
                  fontSize: 16 * settings.fontSize,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
              if (settings.storeAddress.isNotEmpty)
                Text(
                  settings.storeAddress,
                  style: TextStyle(fontSize: 11 * settings.fontSize, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              if (settings.storePhone.isNotEmpty)
                Text(
                  'Telp: ${settings.storePhone}',
                  style: TextStyle(fontSize: 11 * settings.fontSize, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              const Divider(height: 16),

              // --- Custom header text ---
              if (settings.headerText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    settings.headerText,
                    style: TextStyle(
                      fontSize: 11 * settings.fontSize,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // --- Receipt Info ---
              _previewRow('No. Struk', 'INV-2024-0001', settings.fontSize, textColor),
              _previewRow('Tanggal', '28/06/2024 14:30', settings.fontSize, textColor),
              if (settings.showCashierName)
                _previewRow('Kasir', 'Tukang Frontend Bot', settings.fontSize, textColor),
              _previewRow('Bayar', 'Tunai', settings.fontSize, textColor),
              const Divider(height: 12),

              // --- Items ---
              Text(
                'Pesanan',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12 * settings.fontSize,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              _previewItemRow('Kopi Susu', 2, 40000, settings.fontSize, textColor),
              _previewItemRow('Nasi Goreng', 1, 35000, settings.fontSize, textColor),
              _previewItemRow('Air Mineral', 3, 15000, settings.fontSize, textColor),

              if (settings.showItemBarcode) ...[
                const SizedBox(height: 4),
                Text(
                  '8991001001002',
                  style: TextStyle(
                    fontSize: 9 * settings.fontSize,
                    color: Colors.grey.shade500,
                    letterSpacing: 2,
                  ),
                ),
              ],

              const Divider(height: 12),

              // --- Totals ---
              _previewRow('Subtotal', 'Rp 90.000', settings.fontSize, textColor),
              _previewRow('Diskon', '-Rp 5.000', settings.fontSize, Colors.red),
              if (settings.showTaxInfo)
                _previewRow('Pajak (11%)', 'Rp 9.350', settings.fontSize, textColor),
              const Divider(height: 8),
              _previewRow(
                'Grand Total',
                'Rp 94.350',
                settings.fontSize,
                colorScheme.primary,
                bold: true,
                large: true,
              ),
              const Divider(height: 8),
              _previewRow('Bayar', 'Rp 100.000', settings.fontSize, textColor),
              _previewRow('Kembali', 'Rp 5.650', settings.fontSize, Colors.blue, bold: true),

              const SizedBox(height: 12),

              // --- Footer ---
              if (settings.footerText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    settings.footerText,
                    style: TextStyle(
                      fontSize: 11 * settings.fontSize,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              Text(
                '-- Terima Kasih --',
                style: TextStyle(
                  fontSize: 11 * settings.fontSize,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Ukuran kertas: ${settings.paperSize}',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _previewRow(String label, String value, double fontSize, Color textColor,
      {bool bold = false, bool large = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: (large ? 12 : 11) * fontSize,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: (large ? 13 : 11) * fontSize,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewItemRow(String name, int qty, double total, double fontSize, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(fontSize: 11 * fontSize, color: textColor),
            ),
          ),
          Text(
            '${qty}x',
            style: TextStyle(fontSize: 11 * fontSize, color: textColor),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              'Rp ${_formatPrice(total)}',
              style: TextStyle(
                fontSize: 11 * fontSize,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match.group(1)}.');
  }

  ThemeData get theme => Theme.of(context);
  ReceiptSettingsProvider get prov => context.read<ReceiptSettingsProvider>();
}
