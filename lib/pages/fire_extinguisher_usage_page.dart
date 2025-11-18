// ==== CHANGE START: FIX REAL-TIME UPDATES FOR FIRE EXTINGUISHER USAGE ====
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:livework_view/widgets/colors.dart';
import 'package:livework_view/providers/auth_provider.dart' as livework_auth;
import 'package:livework_view/helpers/localization_helper.dart';

class FireExtinguisherUsage {
  final String id;
  final String location;
  final String reason;
  final DateTime usageDate;
  final String reportedBy;
  final String? reportedById;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? completedBy;
  final String? notes;
  final DateTime createdAt;

  FireExtinguisherUsage({
    required this.id,
    required this.location,
    required this.reason,
    required this.usageDate,
    required this.reportedBy,
    this.reportedById,
    this.isCompleted = false,
    this.completedAt,
    this.completedBy,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'location': location,
      'reason': reason,
      'usageDate': Timestamp.fromDate(usageDate),
      'reportedBy': reportedBy,
      'reportedById': reportedById,
      'isCompleted': isCompleted,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'completedBy': completedBy,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory FireExtinguisherUsage.fromFirestore(
      String id, Map<String, dynamic> data) {
    return FireExtinguisherUsage(
      id: id,
      location: data['location'] ?? '',
      reason: data['reason'] ?? '',
      usageDate: data['usageDate'] != null
          ? (data['usageDate'] as Timestamp).toDate()
          : DateTime.now(),
      reportedBy: data['reportedBy'] ?? 'Unknown',
      reportedById: data['reportedById'],
      isCompleted: data['isCompleted'] ?? false,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      completedBy: data['completedBy'],
      notes: data['notes'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  FireExtinguisherUsage copyWith({
    String? id,
    String? location,
    String? reason,
    DateTime? usageDate,
    String? reportedBy,
    String? reportedById,
    bool? isCompleted,
    DateTime? completedAt,
    String? completedBy,
    String? notes,
    DateTime? createdAt,
  }) {
    return FireExtinguisherUsage(
      id: id ?? this.id,
      location: location ?? this.location,
      reason: reason ?? this.reason,
      usageDate: usageDate ?? this.usageDate,
      reportedBy: reportedBy ?? this.reportedBy,
      reportedById: reportedById ?? this.reportedById,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class FireExtinguisherUsagePage extends StatefulWidget {
  const FireExtinguisherUsagePage({Key? key}) : super(key: key);

  @override
  _FireExtinguisherUsagePageState createState() =>
      _FireExtinguisherUsagePageState();
}

class _FireExtinguisherUsagePageState extends State<FireExtinguisherUsagePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<FireExtinguisherUsage> _usages = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<QuerySnapshot>? _usageSubscription;

  @override
  void initState() {
    super.initState();
    _setupRealtimeListener();
  }

  @override
  void dispose() {
    _usageSubscription?.cancel();
    super.dispose();
  }

  void _setupRealtimeListener() {
    _usageSubscription = _firestore
        .collection('fire_extinguisher_usage')
        .orderBy('usageDate', descending: true)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _usages = snapshot.docs.map((doc) {
            return FireExtinguisherUsage.fromFirestore(
                doc.id, doc.data() as Map<String, dynamic>);
          }).toList();
          _isLoading = false;
          _error = null;
        });
      }
    }, onError: (error) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load fire extinguisher usage records: $error';
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _addUsage({
    required String location,
    required String reason,
    required DateTime usageDate,
    String notes = '',
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      await _firestore.collection('fire_extinguisher_usage').add({
        'location': location,
        'reason': reason,
        'usageDate': Timestamp.fromDate(usageDate),
        'reportedBy': user?.email ?? 'Unknown User',
        'reportedById': user?.uid,
        'isCompleted': false,
        'notes': notes,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to report usage: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markAsCompleted(FireExtinguisherUsage usage) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      await _firestore
          .collection('fire_extinguisher_usage')
          .doc(usage.id)
          .update({
        'isCompleted': true,
        'completedAt': Timestamp.fromDate(DateTime.now()),
        'completedBy': user?.email ?? 'Admin',
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark as completed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteUsage(FireExtinguisherUsage usage) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(translate(context, 'delete_usage_record')),
        content: Text(translate(context, 'delete_usage_confirmation')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(translate(context, 'cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(translate(context, 'delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestore
            .collection('fire_extinguisher_usage')
            .doc(usage.id)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(translate(context, 'usage_deleted_successfully')),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete usage: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider =
        Provider.of<livework_auth.LiveWorkAuthProvider>(context);
    final isAdmin = authProvider.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text(translate(context, 'fire_extinguisher_usage')),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.secondary,
      ),
      body: _isLoading && _usages.isEmpty
          ? Center(child: CircularProgressIndicator())
          : _error != null && _usages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _setupRealtimeListener,
                        child: Text(translate(context, 'retry')),
                      ),
                    ],
                  ),
                )
              : _usages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.fire_extinguisher,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            translate(context, 'no_fire_extinguisher_usage'),
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: _usages.length,
                      itemBuilder: (context, index) {
                        final usage = _usages[index];
                        return _buildUsageCard(usage, isAdmin);
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUsageDialog,
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        child: Icon(Icons.add),
        tooltip: translate(context, 'report_fire_extinguisher_usage'),
      ),
    );
  }

  void _showAddUsageDialog() {
    final _formKey = GlobalKey<FormState>();
    final _locationController = TextEditingController();
    final _reasonController = TextEditingController();
    final _notesController = TextEditingController();
    DateTime _selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(translate(context, 'report_fire_extinguisher_usage')),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: translate(context, 'location'),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return translate(context, 'please_enter_location');
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _reasonController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: translate(context, 'reason_for_usage'),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return translate(context, 'please_enter_reason');
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText:
                            '${translate(context, 'notes')} (${translate(context, 'optional')})',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Text(translate(context, 'usage_date')),
                        SizedBox(width: 16),
                        Expanded(
                          child: TextButton(
                            onPressed: () async {
                              final selectedDate = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate:
                                    DateTime.now().subtract(Duration(days: 30)),
                                lastDate: DateTime.now(),
                              );
                              if (selectedDate != null) {
                                setDialogState(() {
                                  _selectedDate = selectedDate;
                                });
                              }
                            },
                            child: Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(translate(context, 'cancel')),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pop(context);
                    await _addUsage(
                      location: _locationController.text.trim(),
                      reason: _reasonController.text.trim(),
                      notes: _notesController.text.trim(),
                      usageDate: _selectedDate,
                    );
                  }
                },
                child: Text(translate(context, 'submit')),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUsageCard(FireExtinguisherUsage usage, bool isAdmin) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.fire_extinguisher,
                  color: usage.isCompleted ? Colors.green : Colors.red,
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        usage.location,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        usage.isCompleted
                            ? '${translate(context, 'completed')} • ${_formatDate(usage.completedAt!)}'
                            : '${translate(context, 'pending')} • ${_formatDate(usage.usageDate)}',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              usage.isCompleted ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (usage.isCompleted)
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
              ],
            ),
            SizedBox(height: 12),
            Text(
              usage.reason,
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            if (usage.notes != null && usage.notes!.isNotEmpty) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${translate(context, 'notes')}: ${usage.notes}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ),
            ],
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  usage.reportedBy,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Spacer(),
                if (isAdmin && !usage.isCompleted) ...[
                  ElevatedButton.icon(
                    onPressed: () => _markAsCompleted(usage),
                    icon: Icon(Icons.check, size: 16),
                    label: Text(translate(context, 'mark_done')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                  SizedBox(width: 8),
                ],
                if (isAdmin) ...[
                  IconButton(
                    onPressed: () => _deleteUsage(usage),
                    icon: Icon(Icons.delete, size: 20, color: Colors.red),
                    tooltip: translate(context, 'delete'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
// ==== CHANGE END ====