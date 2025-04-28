import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrganizationScreen extends StatefulWidget {
  const OrganizationScreen({super.key});

  @override
  State<OrganizationScreen> createState() => _OrganizationScreenState();
}

class _OrganizationScreenState extends State<OrganizationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _acronymController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _facebookController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  final TextEditingController _uidController = TextEditingController();

  // Show dialog to create organization
  void _showCreateOrganizationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Organization'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Organization Name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _acronymController,
                  decoration: const InputDecoration(labelText: 'Acronym'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _categoryController,
                  decoration: const InputDecoration(labelText: 'Category (comma separated)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _facebookController,
                  decoration: const InputDecoration(labelText: 'Facebook'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _mobileController,
                  decoration: const InputDecoration(labelText: 'Mobile'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _statusController,
                  decoration: const InputDecoration(labelText: 'Status (Active/Inactive)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _uidController,
                  decoration: const InputDecoration(labelText: 'UID'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _clearFields();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await _createOrganization();
                if (success) {
                  Navigator.pop(context);
                  _clearFields();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Create new organization and save to Firestore
  Future<bool> _createOrganization() async {
    final String name = _nameController.text.trim();
    final String acronym = _acronymController.text.trim();
    final String categoryString = _categoryController.text.trim();
    final List<String> category = categoryString.isNotEmpty
        ? categoryString.split(',').map((e) => e.trim()).toList()
        : []; // Split the category string into a list
    final String email = _emailController.text.trim();
    final String facebook = _facebookController.text.trim();
    final String mobile = _mobileController.text.trim();
    final String status = _statusController.text.trim(); // Active/Inactive
    final String uid = _uidController.text.trim(); // User ID

    // Assign image URLs based on the organization name
    String imageUrl = '';
    if (name == 'Running Club') {
      imageUrl = 'https://images.pexels.com/photos/4920429/pexels-photo-4920429.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1';
    } else if (name == 'Cateneo') {
      imageUrl = 'https://images.pexels.com/photos/2286016/pexels-photo-2286016.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1';
    }

    if (name.isEmpty || acronym.isEmpty || category.isEmpty || email.isEmpty || facebook.isEmpty || mobile.isEmpty || status.isEmpty || uid.isEmpty) {
      return false; // Ensure all fields are filled
    }

    try {
      await FirebaseFirestore.instance.collection('organizations').add({
        'name': name,
        'acronym': acronym,
        'category': category, // Save category as an array
        'email': email,
        'facebook': facebook,
        'mobile': mobile,
        'status': status,
        'uid': uid,
        'imageUrl': imageUrl, // Save image URL for the organization
        'createdAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('Error saving organization: $e');
      return false;
    }
  }

  // Clear the form fields after saving or canceling
  void _clearFields() {
    _nameController.clear();
    _acronymController.clear();
    _categoryController.clear();
    _emailController.clear();
    _facebookController.clear();
    _mobileController.clear();
    _statusController.clear();
    _uidController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Organizations"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            FloatingActionButton.extended(
              onPressed: _showCreateOrganizationDialog,
              label: const Text('Create Organization'),
              icon: const Icon(Icons.add),
            ),
            const SizedBox(height: 30),
            const Text(
              "My Organizations:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('organizations')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No organizations found.'));
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final name = doc['name'];
                      final acronym = doc['acronym'];
                      final category = List<String>.from(doc['category']); // Convert category to list
                      final email = doc['email'];
                      final facebook = doc['facebook'];
                      final mobile = doc['mobile'];
                      final status = doc['status'];
                      final uid = doc['uid'];
                      final imageUrl = doc['imageUrl'];

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 3, // Lower elevation for a flatter card
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  imageUrl,
                                  height: 120,  // Adjust image size
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const SizedBox(
                                      height: 120,
                                      child: Center(child: Text('Image load error')),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text('Acronym: $acronym'),
                              Text('Categories: ${category.join(', ')}'), // Display categories as a comma-separated string
                              Text('Email: $email'),
                              Text('Facebook: $facebook'),
                              Text('Mobile: $mobile'),
                              Text('Status: $status'),
                              Text('UID: $uid'),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 