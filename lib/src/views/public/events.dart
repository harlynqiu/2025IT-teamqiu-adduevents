import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _eventDescriptionController = TextEditingController();
  final TextEditingController _eventLocationController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedOrganizationId;
  String? _selectedStatus;
  String? _selectedOrganizationImageUrl;

  final List<String> _statusOptions = ['Scheduled', 'On-going', 'Cancelled'];

  void _showCreateEventDialog(List<QueryDocumentSnapshot> organizations) {
    if (organizations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create an organization first!')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Event'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _eventNameController,
                  decoration: const InputDecoration(labelText: 'Event Name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _eventDescriptionController,
                  decoration: const InputDecoration(labelText: 'Event Description'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _eventLocationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedDate == null
                            ? 'Select Event Date'
                            : 'Date: ${_selectedDate!.toLocal()}'.split(' ')[0],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _pickDate,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedOrganizationId,
                  hint: const Text('Select Organization'),
                  items: organizations.map((org) {
                    return DropdownMenuItem<String>(
                      value: org.id,
                      child: Text(org['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedOrganizationId = value;
                      if (value != null) {
                        final selectedOrg = organizations.firstWhere((org) => org.id == value);
                        _selectedOrganizationImageUrl = selectedOrg['organizationImageUrl'] ?? '';
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),
                if (_selectedOrganizationImageUrl != null && _selectedOrganizationImageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      _selectedOrganizationImageUrl!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  hint: const Text('Select Event Status'),
                  items: _statusOptions.map((status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  },
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
                final success = await _createEvent();
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

  Future<void> _pickDate() async {
    DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<bool> _createEvent() async {
    final String name = _eventNameController.text.trim();
    final String description = _eventDescriptionController.text.trim();
    final String location = _eventLocationController.text.trim();
    final String? organizationId = _selectedOrganizationId;
    final String? status = _selectedStatus;

    if (name.isEmpty || description.isEmpty || location.isEmpty || _selectedDate == null || organizationId == null || status == null) {
      return false;
    }

    try {
      // Fetch the organization to get the imageUrl
      final orgDoc = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .get();

      // Set the imageUrl based on the organization's document
      _selectedOrganizationImageUrl = orgDoc['organizationImageUrl'] ?? '';

      final eventData = {
        'name': name,
        'description': description,
        'location': location,
        'date': _selectedDate!.toIso8601String().split('T')[0], // YYYY-MM-DD format
        'status': status,
        'organizationId': organizationId,
        'createdAt': Timestamp.now(),
      };

      // Add the organization image URL only if it's not null or empty
      if (_selectedOrganizationImageUrl != null && _selectedOrganizationImageUrl!.isNotEmpty) {
        eventData['organizationImageUrl'] = _selectedOrganizationImageUrl!;
      }

      await FirebaseFirestore.instance.collection('events').add(eventData);
      return true;
    } catch (e) {
      print('Error creating event: $e');
      return false;
    }
  }

  void _clearFields() {
    _eventNameController.clear();
    _eventDescriptionController.clear();
    _eventLocationController.clear();
    _selectedDate = null;
    _selectedOrganizationId = null;
    _selectedOrganizationImageUrl = null;
    _selectedStatus = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('organizations').snapshots(),
              builder: (context, orgSnapshot) {
                if (orgSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final organizations = orgSnapshot.data?.docs ?? [];

                return FloatingActionButton.extended(
                  onPressed: () => _showCreateEventDialog(organizations),
                  label: const Text('Create Event'),
                  icon: const Icon(Icons.add),
                );
              },
            ),
            const SizedBox(height: 30),
            const Text(
              "My Events:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('events')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, eventSnapshot) {
                  if (eventSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!eventSnapshot.hasData || eventSnapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No events found.'));
                  }

                  return ListView.builder(
                    itemCount: eventSnapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = eventSnapshot.data!.docs[index];
                      final name = doc['name'];
                      final description = doc['description'];
                      final location = doc['location'];
                      final date = doc['date'];
                      final status = doc['status'];
                      final organizationId = doc['organizationId'];
                      final organizationImageUrl = doc['organizationImageUrl'] ?? '';

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (organizationImageUrl.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    organizationImageUrl,
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              const SizedBox(height: 10),
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text('Description: $description'),
                              Text('Location: $location'),
                              Text('Date: $date'),
                              Text('Status: $status'),
                              Text('Organization ID: $organizationId'),
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
