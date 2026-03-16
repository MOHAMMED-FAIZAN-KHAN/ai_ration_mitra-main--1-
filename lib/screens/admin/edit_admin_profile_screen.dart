import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../providers/auth_provider.dart';

class EditAdminProfileScreen extends StatefulWidget {
  const EditAdminProfileScreen({super.key});

  @override
  State<EditAdminProfileScreen> createState() => _EditAdminProfileScreenState();
}

class _EditAdminProfileScreenState extends State<EditAdminProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _mobileController;
  late final TextEditingController _officeController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _mobileController = TextEditingController(text: user?.mobileNumber ?? '');
    _officeController = TextEditingController(text: user?.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _officeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Admin Profile')),
      body: _saving
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _field(
                    _nameController,
                    'Name',
                    validator: (value) {
                      if ((value ?? '').trim().length < 2) {
                        return 'Enter valid name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  _field(
                    _emailController,
                    'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      final text = (value ?? '').trim();
                      if (text.isEmpty) return 'Email is required';
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(text)) {
                        return 'Enter valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  _field(
                    _mobileController,
                    'Mobile Number',
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      final digits =
                          (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                      if (digits.length != 10) {
                        return 'Enter 10 digit number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  _field(
                    _officeController,
                    'Office Address',
                    maxLines: 2,
                    validator: (value) {
                      if ((value ?? '').trim().length < 3) {
                        return 'Enter office address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save Changes'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    try {
      final auth = context.read<AuthProvider>();
      final current = auth.currentUser;
      if (current == null) {
        throw Exception('Admin session expired');
      }

      final updated = User(
        id: current.id,
        type: current.type,
        name: _nameController.text.trim(),
        mobileNumber: _mobileController.text.trim(),
        email: _emailController.text.trim(),
        uid: current.uid,
        address: _officeController.text.trim(),
        aadhaarNumber: current.aadhaarNumber,
        category: current.category,
        assignedShop: current.assignedShop,
        fpsId: current.fpsId,
        profileImage: current.profileImage,
      );

      final ok = await auth.updateProfile(updated);
      if (!mounted) return;
      if (!ok) {
        throw Exception(auth.error ?? 'Failed to save profile');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin profile updated')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

