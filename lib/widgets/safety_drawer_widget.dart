import 'package:flutter/material.dart';
import 'package:livework_view/pages/fire_extinguisher_usage_page.dart';
import 'package:livework_view/pages/report_hazards_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:livework_view/widgets/colors.dart';

class SafetyDrawer extends StatelessWidget {
  const SafetyDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Drawer Header
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppColors.background,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 60,
                  height: 60,
                  color: AppColors.secondary,
                ),
                const SizedBox(height: 10),
                Text(
                  'LiveWork Safety',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Drawer Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.emergency,
                  title: 'Emergency Contacts',
                  onTap: () => _showEmergencyContacts(context),
                ),
                _buildDrawerItem(
                  icon: Icons.security,
                  title: 'Safety Guide',
                  onTap: () => _showSafetyGuide(context),
                ),
                _buildDrawerItem(
                  icon: Icons.medical_services,
                  title: 'First Aid Guide',
                  onTap: () => _showFirstAidGuide(context),
                ),
                _buildDrawerItem(
                  icon: Icons.fire_extinguisher,
                  title: 'Fire Extinguisher Usage',
                  onTap: () => _showFireExtinguisherUsage(context),
                ),
// SIMPLEST VERSION - JUST RED DOT ON ICON:
                ListTile(
                  leading: Stack(
                    children: [
                      Icon(
                        Icons.report_problem,
                        color: AppColors.background,
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                        ),
                      ),
                    ],
                  ),
                  title: const Text(
                    'Quick Hazard Reporting',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () => _showQuickHazardReporting(context),
                ),
                // _buildDrawerItem(
                //   icon: Icons.checklist,
                //   title: 'Safety Checklist',
                //   onTap: () => _showSafetyChecklist(context),
                // ),
                _buildDrawerItem(
                  icon: Icons.inventory_2,
                  title: 'Inspections',
                  onTap: () => _showDailyInspections(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppColors.background,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showFireExtinguisherUsage(BuildContext context) {
    Navigator.pop(context); // Close drawer first
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FireExtinguisherUsagePage(),
      ),
    );
  }

  // Drawer Item Handlers
  void _showEmergencyContacts(BuildContext context) {
    final contacts = [
      _ContactItem('Fire Unit', '0750 147 7878 - Radio:4'),
      _ContactItem('Fire Truck', '0750 869 0646 - Radio:4'),
      _ContactItem('HSE', '0750 492 1392 - Radio:4'),
      // _ContactItem('Logistics Officer', '0750 431 8350 - Radio:4'),
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Contacts'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children:
                contacts.map((contact) => _buildContactItem(contact)).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(_ContactItem contact) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              contact.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            contact.number,
            style: TextStyle(color: Colors.blue[700]),
          ),
        ],
      ),
    );
  }

  void _showSafetyGuide(BuildContext context) {
    final guidelines = [
      'Always wear the required PPE for your task',
      'Follow all refinery safety procedures and permits',
      'Report leaks, strange smells, abnormal sounds, and unsafe conditions immediately',
      'Maintain good housekeeping to prevent slips, trips, fire risks, and blocked access routes',
      'Never enter confined spaces without testing, ventilation, permits, and an attendant',
      'Use tools and equipment only if you are trained and authorised',
      'Check for gas hazards before starting work, especially H₂S and LEL',
      'Lockout and tagout all energy sources before maintenance',
      'Know emergency alarms, escape routes, muster points, and how to respond to fires or gas releases',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Safety Guide'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'General Safety Guidelines',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              ...guidelines.map((guide) => _buildGuideItem(guide)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  content: InteractiveViewer(
                    child: Image.asset(
                      'assets/images/safety_tools.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
            child: const Text('Safety Tools'),
          ),
          ElevatedButton(
            onPressed: () async {
              const url = 'https://www.youtube.com/watch?v=bjlAUBNs93Y';
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url),
                    mode: LaunchMode.externalApplication);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not open video')),
                );
              }
            },
            child: const Text('Show Video'),
          ),
        ],
      ),
    );
  }

  void _showFirstAidGuide(BuildContext context) {
    final procedures = [
      'Call emergency services immediately for serious injuries or chemical exposures',
      'Wear gloves before treating any wound to prevent contamination',
      'Stop bleeding by applying direct pressure to the wound',
      'Flush chemical splashes in eyes or on skin with plenty of water for at least 15 minutes',
      'Move injured persons away from hazardous areas if safe to do so',
      'Keep the injured person calm and still until help arrives',
      'Use burn dressings or clean cloths for thermal or chemical burns; avoid applying creams',
      'Perform CPR if the person is unresponsive and not breathing',
      'Report all injuries and near-misses to your supervisor immediately',
      'In case of H₂S exposure, move the person to fresh air and administer oxygen if trained',
      'Treat electrical shock victims only after power has been isolated',
      'Cool heat-related injuries immediately with water and move the person to a shaded area',
      'For inhalation of toxic fumes, loosen clothing and keep the person sitting upright if possible',
      'Keep first aid kits accessible and restock after every use',
      'Ensure all employees are trained in basic first aid and CPR',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('First Aid Guide'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Emergency First Aid Procedures',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              ...procedures.map((procedure) => _buildGuideItem(procedure)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  content: InteractiveViewer(
                    child: Image.asset(
                      'assets/images/first_aid.jpeg',
                      fit: BoxFit.cover,
                    ),
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
            child: const Text('Show Image'),
          ),
          ElevatedButton(
            onPressed: () async {
              const url = 'https://www.youtube.com/watch?v=7XClM6OT2uA';
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url),
                    mode: LaunchMode.externalApplication);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not open video')),
                );
              }
            },
            child: const Text('Show Video'),
          ),
        ],
      ),
    );
  }

  void _showQuickHazardReporting(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Hazard Reporting'),
        content: const Text(
          'Use this feature to quickly report safety hazards.\n\n'
          'For immediate reporting:\n'
          '• Take photos of the hazard\n'
          '• Provide clear description\n'
          '• Note the exact location\n'
          '• Report to supervisor immediately',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog first
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReportHazardsPage(),
                ),
              );
            },
            child: const Text('Report Hazard'),
          ),
        ],
      ),
    );
  }

  // void _showSafetyChecklist(BuildContext context) {
  //   final checklistItems = [
  //     'PPE inspection and proper use',
  //     'Equipment safety checks completed',
  //     'Work area clear of hazards',
  //     'Emergency exits accessible',
  //     'Safety equipment in place',
  //     'Communications equipment working',
  //     'Understand today\'s safety briefing',
  //     'Know emergency procedures',
  //   ];

  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Daily Safety Checklist'),
  //       content: SingleChildScrollView(
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             const Text(
  //               'Complete before starting work:',
  //               style: TextStyle(fontWeight: FontWeight.bold),
  //             ),
  //             const SizedBox(height: 10),
  //             ...checklistItems.map((item) => _buildChecklistItem(item)),
  //           ],
  //         ),
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text('Close'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () {
  //             Navigator.pop(context);
  //             ScaffoldMessenger.of(context).showSnackBar(
  //               const SnackBar(content: Text('Safety checklist completed')),
  //             );
  //           },
  //           child: const Text('Mark Complete'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  void _showDailyInspections(BuildContext context) {
    final inspectionItems = [
      _InspectionItem('Fire extinguishers & fire hoses inspection',
          '(Check pressure, accessibility, damage, expiry dates)'),
      _InspectionItem('Fire truck inspection',
          '(Check water level, hose condition, pump operation, tires, etc)'),
      _InspectionItem('PPE inspection',
          '(Check availability and condition of helmets, gloves, goggles, respirators)'),
      _InspectionItem('Leak inspection',
          '(Look for oil, water, steam, chemical, or gas leaks around equipment and pipes)'),
      _InspectionItem('Housekeeping inspection',
          '(Check for spills, obstacles, tripping hazards, scattered tools)'),
      _InspectionItem('Pumps & rotating equipment inspection',
          '(Abnormal vibrations, noise, overheating, leaks, loose bolts)'),
      _InspectionItem('Electrical cable & panel inspection',
          '(Loose wires, exposed cables, water near electrical boxes)'),
      _InspectionItem('Ladder & scaffold inspection',
          '(Stability, damage, proper tagging, guardrails)'),
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Inspections'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Monthly - weekly - daily Inspections:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...inspectionItems.map((item) => _buildInspectionItem(item)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          // ElevatedButton(
          //   onPressed: () {
          //     Navigator.pop(context);
          //     ScaffoldMessenger.of(context).showSnackBar(
          //       const SnackBar(content: Text('Inspection recorded')),
          //     );
          //   },
          //   child: const Text('Record Inspection'),
          // ),
        ],
      ),
    );
  }

  Widget _buildGuideItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Checkbox(
            value: false,
            onChanged: (value) {
              // Handle checkbox state
            },
          ),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildInspectionItem(_InspectionItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  item.frequency,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }
}

class _ContactItem {
  final String name;
  final String number;

  _ContactItem(this.name, this.number);
}

class _InspectionItem {
  final String name;
  final String frequency;

  _InspectionItem(this.name, this.frequency);
}
