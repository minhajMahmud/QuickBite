import 'package:flutter/material.dart';

/// Model for address
class Address {
  final String id;
  final String label;
  final String address;
  final String cityStateZip;
  final bool isDefault;

  Address({
    required this.id,
    required this.label,
    required this.address,
    required this.cityStateZip,
    this.isDefault = false,
  });

  /// Create a copy with modified fields
  Address copyWith({
    String? id,
    String? label,
    String? address,
    String? cityStateZip,
    bool? isDefault,
  }) {
    return Address(
      id: id ?? this.id,
      label: label ?? this.label,
      address: address ?? this.address,
      cityStateZip: cityStateZip ?? this.cityStateZip,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

/// Dialog to add or edit address
class AddAddressDialog extends StatefulWidget {
  final Function(Address) onSave;
  final Address? initialAddress;

  const AddAddressDialog({
    Key? key,
    required this.onSave,
    this.initialAddress,
  }) : super(key: key);

  @override
  State<AddAddressDialog> createState() => _AddAddressDialogState();
}

class _AddAddressDialogState extends State<AddAddressDialog> {
  late TextEditingController _labelController;
  late TextEditingController _addressController;
  late TextEditingController _cityStateZipController;
  late bool _isDefault;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(
      text: widget.initialAddress?.label ?? '',
    );
    _addressController = TextEditingController(
      text: widget.initialAddress?.address ?? '',
    );
    _cityStateZipController = TextEditingController(
      text: widget.initialAddress?.cityStateZip ?? '',
    );
    _isDefault = widget.initialAddress?.isDefault ?? false;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _addressController.dispose();
    _cityStateZipController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_labelController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _cityStateZipController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final address = Address(
      id: widget.initialAddress?.id ??
          'addr_${DateTime.now().millisecondsSinceEpoch}',
      label: _labelController.text,
      address: _addressController.text,
      cityStateZip: _cityStateZipController.text,
      isDefault: _isDefault,
    );

    widget.onSave(address);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.initialAddress != null
                        ? 'Edit Address'
                        : 'Add New Address',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close,
                      size: 24,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Label Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Label',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _labelController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Home, Work',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Address Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Address',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      hintText: 'Street address',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // City, State, ZIP Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'City, State, ZIP',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _cityStateZipController,
                    decoration: InputDecoration(
                      hintText: 'City, State ZIP',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Set as default checkbox
              Row(
                children: [
                  Checkbox(
                    value: _isDefault,
                    onChanged: (value) {
                      setState(() {
                        _isDefault = value ?? false;
                      });
                    },
                  ),
                  Text(
                    'Set as default address',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Address',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
