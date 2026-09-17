import 'package:flutter/material.dart';

import 'package:mobile/features/checkout/data/models/delivery_address_model.dart';

class DeliveryAddressScreen extends StatefulWidget {
  const DeliveryAddressScreen({super.key, required this.onAddressSelected});

  final ValueChanged<DeliveryAddress> onAddressSelected;

  @override
  State<DeliveryAddressScreen> createState() => _DeliveryAddressScreenState();
}

class _DeliveryAddressScreenState extends State<DeliveryAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();

    super.dispose();
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final address = DeliveryAddress(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      addressLine: _addressController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      pincode: _pincodeController.text.trim(),
    );

    widget.onAddressSelected(address);
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    final phone = value.trim();

    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      return 'Enter a valid 10-digit phone number';
    }

    return null;
  }

  String? _validatePincode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Pincode is required';
    }

    final pincode = value.trim();

    if (!RegExp(r'^\d{6}$').hasMatch(pincode)) {
      return 'Enter a valid 6-digit pincode';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Address')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Where should we deliver?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your delivery details to continue.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),

              _AddressField(
                controller: _nameController,
                label: 'Full Name',
                hint: 'Enter your name',
                icon: Icons.person_outline,
                validator: (value) {
                  return _validateRequired(value, 'Name');
                },
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: 16),

              _AddressField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: '10-digit mobile number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: _validatePhone,
                textInputAction: TextInputAction.next,
                maxLength: 10,
              ),

              const SizedBox(height: 16),

              _AddressField(
                controller: _addressController,
                label: 'Address',
                hint: 'House number, street, area',
                icon: Icons.home_outlined,
                validator: (value) {
                  return _validateRequired(value, 'Address');
                },
                textInputAction: TextInputAction.next,
                maxLines: 3,
              ),

              const SizedBox(height: 16),

              _AddressField(
                controller: _cityController,
                label: 'City',
                hint: 'Enter your city',
                icon: Icons.location_city_outlined,
                validator: (value) {
                  return _validateRequired(value, 'City');
                },
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: 16),

              _AddressField(
                controller: _stateController,
                label: 'State',
                hint: 'Enter your state',
                icon: Icons.map_outlined,
                validator: (value) {
                  return _validateRequired(value, 'State');
                },
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: 16),

              _AddressField(
                controller: _pincodeController,
                label: 'Pincode',
                hint: '6-digit pincode',
                icon: Icons.pin_drop_outlined,
                keyboardType: TextInputType.number,
                validator: _validatePincode,
                textInputAction: TextInputAction.done,
                maxLength: 6,
              ),

              const SizedBox(height: 28),

              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: _continue,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressField extends StatelessWidget {
  const _AddressField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.validator,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.maxLength,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int maxLines;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      maxLength: maxLength,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
