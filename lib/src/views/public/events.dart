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
  final TextEditingController _eventDateController = TextEditingController();
  String? _selectedOrganizationId;
  String? _selectedStatus;

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
                TextField(
                  controller: _eventDateController,
                  decoration: const InputDecoration(labelText: 'Event Date (YYYY-MM-DD)'),
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
                    });
                  },
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

  Future<bool> _createEvent() async {
    final String name = _eventNameController.text.trim();
    final String description = _eventDescriptionController.text.trim();
    final String location = _eventLocationController.text.trim();
    final String date = _eventDateController.text.trim();
    final String? organizationId = _selectedOrganizationId;
    final String? status = _selectedStatus;

    if (name.isEmpty || description.isEmpty || location.isEmpty || date.isEmpty || organizationId == null || status == null) {
      return false;
    }

    try {
      await FirebaseFirestore.instance.collection('events').add({
        'name': name,
        'description': description,
        'location': location,
        'date': date,
        'status': status,
        'organizationId': organizationId,
        'createdAt': Timestamp.now(),
      });
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
    _eventDateController.clear();
    _selectedOrganizationId = null;
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
