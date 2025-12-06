import 'package:flutter/material.dart';
import 'package:livework_view/widgets/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyContactsPage extends StatefulWidget {
  const EmergencyContactsPage({Key? key}) : super(key: key);

  @override
  _EmergencyContactsPageState createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends State<EmergencyContactsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  List<bool> _contactVisibility = [];
  List<Animation<double>> _contactAnimations = [];

  final List<ContactItem> _contacts = [
    ContactItem(
      name: 'Fire Unit - Zinar',
      number: '07501477878',
      displayNumber: '0750 147 7878',
      details: 'Radio: 4',
      icon: Icons.local_fire_department,
      color: Colors.red,
    ),
    ContactItem(
      name: 'Fire Truck - Shahab',
      number: '07508690646',
      displayNumber: '0750 869 0646',
      details: 'Radio: 4',
      icon: Icons.fire_truck,
      color: Colors.redAccent,
    ),
    ContactItem(
      name: 'HSE Department - Roj',
      number: '07504921392',
      displayNumber: '0750 492 1392',
      details: 'Radio: 4',
      icon: Icons.security,
      color: Colors.blue,
    ),
    ContactItem(
      name: 'Maintenance Supervisor - Zeravan',
      number: '07504318350',
      displayNumber: '0750 431 8350',
      details: 'Radio: 4',
      icon: Icons.supervisor_account,
      color: Colors.orange,
    ),
    ContactItem(
      name: 'Security Control',
      number: '0751 149 7616',
      displayNumber: '0751 149 7616',
      details: 'Radio: 1',
      icon: Icons.security,
      color: Colors.purple,
    ),
    ContactItem(
      name: 'Medical Emergency',
      number: '066 122',
      displayNumber: '066 122',
      details: 'Emergency Services',
      icon: Icons.medical_services,
      color: Colors.green,
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Initialize visibility list
    _contactVisibility = List.generate(_contacts.length, (index) => false);

    // Setup animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Create staggered animations for each contact
    for (int i = 0; i < _contacts.length; i++) {
      final delay = i * 200; // 200ms delay between each contact
      final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            delay / (_contacts.length * 200 + 200),
            (delay + 600) / (_contacts.length * 200 + 600),
            curve: Curves.easeOut,
          ),
        ),
      );
      _contactAnimations.add(animation);
    }

    // Start animations with delay
    Future.delayed(const Duration(milliseconds: 300), () {
      _animationController.forward();
    });

    // Update visibility as animations progress
    _animationController.addListener(() {
      for (int i = 0; i < _contactAnimations.length; i++) {
        if (_contactAnimations[i].value > 0.1 && !_contactVisibility[i]) {
          setState(() {
            _contactVisibility[i] = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _callNumber(String number, String name) async {
    final url = Uri.parse('tel:$number');

    // Show confirmation dialog for important calls
    if (number != "911" && number != "066122") {
      bool? shouldCall = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Call $name?'),
          content: Text('Do you want to call $name?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Call'),
            ),
          ],
        ),
      );

      if (shouldCall != true) return;
    }

    // Try to launch the phone dialer
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      // If can't launch directly, show error and copy to clipboard
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Could not make call. Number copied to clipboard: $number'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Copy',
            onPressed: () {
              // You can use clipboard package if needed
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Number copied: $number'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.secondary,
        elevation: 0,
      ),
      body: Container(
        color: AppColors.background,
        child: Column(
          children: [
            // Header with emergency icon
            // Container(
            //   padding: const EdgeInsets.all(20),
            //   color: Colors.red.withOpacity(0.1),
            //   child: Row(
            //     children: [
            //       Icon(
            //         Icons.emergency,
            //         color: Colors.red,
            //         size: 40,
            //       ),
            //       const SizedBox(width: 15),
            //       Expanded(
            //         child: Column(
            //           crossAxisAlignment: CrossAxisAlignment.start,
            //           children: [
            //             Text(
            //               'EMERGENCY CONTACTS',
            //               style: TextStyle(
            //                 fontSize: 18,
            //                 fontWeight: FontWeight.bold,
            //                 color: Colors.red,
            //               ),
            //             ),
            //             const SizedBox(height: 4),
            //             Text(
            //               'Tap any contact to call immediately',
            //               style: TextStyle(
            //                 fontSize: 14,
            //                 color: Colors.grey[700],
            //               ),
            //             ),
            //           ],
            //         ),
            //       ),
            //     ],
            //   ),
            // ),

            // Animated contacts list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _contacts.length,
                itemBuilder: (context, index) {
                  final contact = _contacts[index];
                  final animation = _contactAnimations[index];
                  final isVisible = _contactVisibility[index];

                  return AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          0,
                          (1 - animation.value) * 50, // Slide up effect
                        ),
                        child: Opacity(
                          opacity: animation.value,
                          child: child,
                        ),
                      );
                    },
                    child: GestureDetector(
                      onTap: () => _callNumber(contact.number, contact.name),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Contact Icon
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: contact.color.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  contact.icon,
                                  color: contact.color,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Contact Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      contact.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      contact.number,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      contact.details,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Call Button
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.phone,
                                  color: Colors.green,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Footer Note
            // Container(
            //   padding: const EdgeInsets.all(16),
            //   color: Colors.grey[50],
            //   child: Row(
            //     children: [
            //       Icon(
            //         Icons.info,
            //         color: Colors.blue,
            //         size: 20,
            //       ),
            //       const SizedBox(width: 10),
            //       Expanded(
            //         child: Text(
            //           'All emergency calls are recorded for safety purposes',
            //           style: TextStyle(
            //             fontSize: 12,
            //             color: Colors.grey[600],
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

class ContactItem {
  final String name;
  final String number;
  final String displayNumber;
  final String details;
  final IconData icon;
  final Color color;

  ContactItem({
    required this.name,
    required this.number,
    required this.displayNumber,
    required this.details,
    required this.icon,
    required this.color,
  });
}
