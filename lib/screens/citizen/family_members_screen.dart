import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/family_member.dart';
import '../../providers/family_member_provider.dart';

class FamilyMembersScreen extends StatefulWidget {
  const FamilyMembersScreen({Key? key}) : super(key: key);

  @override
  State<FamilyMembersScreen> createState() => _FamilyMembersScreenState();
}

class _FamilyMembersScreenState extends State<FamilyMembersScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _relationController;
  late TextEditingController _uidController;
  bool _isEditing = false;
  String? _editingMemberId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _ageController = TextEditingController();
    _relationController = TextEditingController();
    _uidController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _relationController.dispose();
    _uidController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _nameController.clear();
    _ageController.clear();
    _relationController.clear();
    _uidController.clear();
    setState(() {
      _isEditing = false;
      _editingMemberId = null;
    });
  }

  void _editMember(FamilyMember member) {
    _nameController.text = member.name;
    _ageController.text = member.age.toString();
    _relationController.text = member.relation;
    _uidController.text = member.uid ?? '';
    setState(() {
      _isEditing = true;
      _editingMemberId = member.id;
    });
    _showFormDialog();
  }

  void _showFormDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isEditing ? 'Edit Family Member' : 'Add Family Member'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    hintText: 'Enter family member name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Age',
                    hintText: 'Enter age',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter age';
                    }
                    final age = int.tryParse(value);
                    if (age == null || age <= 0 || age > 150) {
                      return 'Please enter a valid age (1-150)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _relationController,
                  decoration: InputDecoration(
                    labelText: 'Relation',
                    hintText: 'e.g., Mother, Father, Brother, Sister, Spouse',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter relation';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _uidController,
                  decoration: InputDecoration(
                    labelText: 'Aadhar/UID (Optional)',
                    hintText: 'Enter Aadhar or UID number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _clearForm();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final provider = context.read<FamilyMemberProvider>();

                if (_isEditing && _editingMemberId != null) {
                  await provider.updateFamilyMember(
                    id: _editingMemberId!,
                    name: _nameController.text,
                    age: int.parse(_ageController.text),
                    relation: _relationController.text,
                    uid: _uidController.text.isEmpty
                        ? null
                        : _uidController.text,
                  );
                } else {
                  await provider.addFamilyMember(
                    name: _nameController.text,
                    age: int.parse(_ageController.text),
                    relation: _relationController.text,
                    uid: _uidController.text.isEmpty
                        ? null
                        : _uidController.text,
                  );
                }

                _clearForm();
                if (context.mounted) {
                  Navigator.of(context).pop();
                  if (provider.error == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _isEditing
                              ? 'Family member updated successfully'
                              : 'Family member added successfully',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              }
            },
            child: Text(_isEditing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(FamilyMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Family Member'),
        content: Text(
          'Are you sure you want to delete ${member.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = context.read<FamilyMemberProvider>();
              await provider.deleteFamilyMember(member.id);
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Family member deleted successfully'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Members'),
        backgroundColor: const Color(0xFF006241),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Consumer<FamilyMemberProvider>(
              builder: (context, provider, _) {
                return Center(
                  child: Text(
                    '${provider.familyMemberCount} members',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Consumer<FamilyMemberProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${provider.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.clearError();
                    },
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            );
          }

          if (provider.familyMembers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.family_restroom,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No family members added yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      _clearForm();
                      _showFormDialog();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Member'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006241),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.familyMembers.length,
            itemBuilder: (context, index) {
              final member = provider.familyMembers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF006241),
                    child: Text(
                      member.name[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(member.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        '${member.relation} • Age: ${member.age}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (member.uid != null && member.uid!.isNotEmpty)
                        Text(
                          'UID: ${member.uid}',
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Text('Edit'),
                        onTap: () => _editMember(member),
                      ),
                      PopupMenuItem(
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                        onTap: () => _showDeleteConfirmation(member),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _clearForm();
          _showFormDialog();
        },
        backgroundColor: const Color(0xFF006241),
        child: const Icon(Icons.add),
      ),
    );
  }
}
