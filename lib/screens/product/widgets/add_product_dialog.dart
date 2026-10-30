import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/product.dart';
import '../../../providers/cashier_provider.dart';
import '../../../theme/app_theme.dart';

class AddProductDialog extends ConsumerStatefulWidget {
  const AddProductDialog({super.key});

  @override
  ConsumerState<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends ConsumerState<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _unitController = TextEditingController();
  final _hppController = TextEditingController();
  final _retailController = TextEditingController();
  final _wholesaleController = TextEditingController();
  final _sackController = TextEditingController();
  final _stockController = TextEditingController();

  // Dropdown satuan unit
  String _selectedUnit = 'Sak';
  final List<String> _unitOptions = [
    'Sak',
    'Kg',
    'Sak (30Kg)',
    'Sak (25Kg)',
    'Sak (10Kg)',
    'Pcs',
    'Kardus (20 Pcs)',
  ];

  // Fungsi untuk menetapkan conversionFactor secara otomatis berdasarkan satuan yang dipilih
  double _getConversionFactorForUnit(String unit) {
    switch (unit) {
      case 'Sak (30kg)':
        return 30.0;
      case 'Sak (25kg)':
        return 25.0;
      case 'Sak (10kg)':
        return 10.0;
      case 'Kardus (20 Pcs)':
        return 20.0;
      case 'Pcs':
        return 1.0;
      case 'Kg':
        return 1.0;
      case 'Sak':
      default:
        return 50.0; // Standar 1 Sak = 50kg
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _unitController.dispose();
    _hppController.dispose();
    _retailController.dispose();
    _wholesaleController.dispose();
    _sackController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      final calculatedConversion = _getConversionFactorForUnit(_selectedUnit);
      final newProduct = Product(
        id: 'PROD-${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        category: _categoryController.text.trim(),
        unit: _selectedUnit,
        hpp: double.parse(_hppController.text.replaceAll('.', '')),
        retailPrice: double.parse(_retailController.text.replaceAll('.', '')),
        wholesalePrice: double.parse(
          _wholesaleController.text.replaceAll('.', ''),
        ),
        sackPrice: double.parse(_sackController.text.replaceAll('.', '')),
        stock: double.parse(_stockController.text),
        conversionFactor: calculatedConversion,
      );
      final currentProducts = ref.read(rawProductsProvider);
      ref.read(rawProductsProvider.notifier).updateProducts([
        ...currentProducts,
        newProduct,
      ]);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produk berhasil ditambahkan!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(20),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tambah Produk Baru',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMain,
                  ),
                ),
                const SizedBox(height: 16),
                _buildField(
                  _nameController,
                  'Nama Produk',
                  'Misal : 511 Pakan Ayam',
                ),
                _buildField(
                  _categoryController,
                  'Kategori Produk',
                  'Misal : Ayam / Sapi / Ikan',
                ),
                // Padding dropdown satuan unit
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Satuan unit',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMain,
                        ),
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedUnit,
                        items: _unitOptions.map((unit) {
                          return DropdownMenuItem(
                            value: unit,
                            child: Text(
                              unit,
                              style: const FontSize130rNormal(),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedUnit = val);
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppTheme.bgCanvas,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildField(
                  _hppController,
                  'HPP (Modal per Satuan Utama/Sak/Kardus/Kg)',
                  'Rp',
                  isNumber: true,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        _retailController,
                        'Harga Eceran (per Kg/Pcs)',
                        'Rp',
                        isNumber: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildField(
                        _wholesaleController,
                        'Harga Grosir (per Kg/Pcs)',
                        'Rp',
                        isNumber: true,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        _sackController,
                        'Harga Sak / Kardus',
                        'Rp',
                        isNumber: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildField(
                        _stockController,
                        'Stok Awal',
                        '0',
                        isNumber: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Batal',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primarySky,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Simpan Produk'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    String hint, {
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMain,
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Wajib diisi' : null,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: 12,
                color: AppTheme.textMuted,
              ),
              filled: true,
              fillColor: AppTheme.bgCanvas,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FontSize130rNormal extends TextStyle {
  const FontSize130rNormal();
  @override
  double? get fontSize => 13.0;
}
