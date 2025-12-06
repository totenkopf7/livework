import 'package:flutter/material.dart';
import 'package:livework_view/widgets/colors.dart';

class InspectionsPage extends StatefulWidget {
  const InspectionsPage({Key? key}) : super(key: key);

  @override
  _InspectionsPageState createState() => _InspectionsPageState();
}

class _InspectionsPageState extends State<InspectionsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  List<bool> _inspectionVisibility = [];
  List<Animation<double>> _inspectionAnimations = [];
  List<bool> _isExpandedList = [];

  final List<InspectionItem> _inspectionItems = [
    InspectionItem(
      id: 1,
      title: 'Fire Extinguishers & Fire Hoses',
      frequency: 'Monthly',
      description: 'Check pressure, accessibility, damage, and expiry dates',
      tasks: [
        'Check pressure gauge is in green zone',
        'Verify accessibility (not blocked)',
        'Inspect for physical damage or corrosion',
        'Check inspection tag and expiry date',
        'Ensure pin and seal are intact',
        'Verify hose is properly coiled and undamaged',
      ],
      icon: Icons.fire_extinguisher,
      color: Colors.red,
      priority: 'HIGH',
    ),
    InspectionItem(
      id: 2,
      title: 'Fire Truck Inspection',
      frequency: 'Weekly',
      description: 'Check water level, hose condition, pump operation, tires',
      tasks: [
        'Check water tank level',
        'Inspect all hoses for damage or leaks',
        'Test pump operation (if scheduled)',
        'Check tire pressure and condition',
        'Verify all emergency lights are working',
        'Check fuel and oil levels',
        'Test siren and communication equipment',
      ],
      icon: Icons.fire_truck,
      color: Colors.redAccent,
      priority: 'HIGH',
    ),
    InspectionItem(
      id: 11,
      title: 'Kitchen Safety Inspection',
      frequency: 'Weekly',
      description: 'Check food safety, equipment, and hygiene standards',
      tasks: [
        'Check refrigerator temperatures (below 5°C/41°F)',
        'Verify freezer temperatures (below -18°C/0°F)',
        'Inspect food storage for proper labeling and dating',
        'Check cooking equipment for cleanliness and proper operation',
        'Verify fire suppression system is accessible and tagged',
        'Inspect ventilation hoods and filters for grease buildup',
        'Check knife storage and safety procedures',
        'Verify all staff are wearing appropriate PPE (aprons, gloves)',
        'Test emergency shut-off switches for cooking equipment',
        'Check for slip hazards and floor condition',
        'Inspect dishwashing area for proper chemical storage',
        'Verify first aid kit is stocked and accessible',
        'Check waste disposal area for cleanliness and pest control',
        'Test kitchen fire extinguishers (Class K)',
        'Verify hot water temperature (above 60°C/140°F for sanitizing)',
      ],
      icon: Icons.kitchen,
      color: Colors.orange.shade700,
      priority: 'HIGH',
    ),
    InspectionItem(
      id: 12,
      title: 'Dining Area Inspection',
      frequency: 'Weekly',
      description: 'Check cleanliness, safety, and customer comfort',
      tasks: [
        'Check table surfaces for cleanliness and sanitization',
        'Verify chair stability and condition',
        'Inspect floor condition for slip hazards',
        'Check lighting levels in dining area',
        'Verify emergency exits are clearly marked and unobstructed',
        'Test emergency lighting system',
        'Check temperature control (AC/heating)',
        'Inspect glassware and utensils for cleanliness',
        'Verify condiment stations are clean and stocked',
        'Check high chairs and booster seats for safety',
        'Inspect carpet/flooring for stains or damage',
        'Verify fire extinguishers are accessible and tagged',
        'Test smoke detectors functionality',
        'Check for pest control issues',
        'Verify hand sanitizer stations are filled',
      ],
      icon: Icons.restaurant,
      color: Colors.brown,
      priority: 'MEDIUM',
    ),
    InspectionItem(
      id: 13,
      title: 'Dry Store Inspection',
      frequency: 'Weekly',
      description: 'Check storage conditions, pest control, and organization',
      tasks: [
        'Check temperature and humidity levels',
        'Inspect for signs of pests (rodents, insects)',
        'Verify FIFO (First In, First Out) system is followed',
        'Check food items for proper labeling and expiration dates',
        'Inspect shelving for stability and cleanliness',
        'Verify adequate spacing between stored items',
        'Check for proper storage of chemicals (separate from food)',
        'Inspect floor condition and cleanliness',
        'Verify adequate lighting throughout storage area',
        'Check door seals and closures',
        'Inspect for water leaks or moisture issues',
        'Verify fire safety equipment is accessible',
        'Check electrical panels for obstructions',
        'Inspect ventilation system operation',
        'Verify emergency exit is clear and functional',
      ],
      icon: Icons.store,
      color: Colors.amber.shade800,
      priority: 'MEDIUM',
    ),
    InspectionItem(
      id: 4,
      title: 'Leak Inspection',
      frequency: 'Twice Daily',
      description: 'Look for oil, water, steam, chemical, or gas leaks',
      tasks: [
        'Check all pump seals and gaskets',
        'Inspect pipe flanges and connections',
        'Look for pooling liquids under equipment',
        'Check for steam leaks in insulated lines',
        'Use gas detectors for H₂S and LEL',
        'Monitor for unusual odors',
        'Check valve packing glands',
      ],
      icon: Icons.opacity,
      color: Colors.orange,
      priority: 'HIGH',
    ),
    InspectionItem(
      id: 5,
      title: 'Housekeeping Inspection',
      frequency: 'Continuous',
      description: 'Check for spills, obstacles, tripping hazards',
      tasks: [
        'Clear walkways and emergency routes',
        'Clean up spills immediately',
        'Store tools and materials properly',
        'Remove waste and debris',
        'Check for slippery surfaces',
        'Verify proper waste segregation',
        'Inspect storage areas for order',
      ],
      icon: Icons.cleaning_services,
      color: Colors.green,
      priority: 'MEDIUM',
    ),
    InspectionItem(
      id: 6,
      title: 'Pumps & Rotating Equipment',
      frequency: 'Daily',
      description: 'Check for abnormal vibrations, noise, overheating',
      tasks: [
        'Listen for unusual noises',
        'Check for excessive vibration',
        'Feel for overheating (use back of hand)',
        'Look for oil leaks at seals',
        'Check lubrication levels',
        'Verify guardings are in place',
        'Check coupling alignment',
      ],
      icon: Icons.build,
      color: Colors.brown,
      priority: 'HIGH',
    ),
    InspectionItem(
      id: 7,
      title: 'Electrical Cable & Panel',
      frequency: 'Daily',
      description: 'Check for loose wires, exposed cables, water ingress',
      tasks: [
        'Inspect cables for damage or wear',
        'Check panel doors are closed and locked',
        'Look for water near electrical equipment',
        'Verify no exposed conductors',
        'Check grounding connections',
        'Look for signs of overheating',
        'Verify area clear of combustible materials',
      ],
      icon: Icons.electrical_services,
      color: Colors.yellow.shade800,
      priority: 'HIGH',
    ),
    InspectionItem(
      id: 8,
      title: 'Ladder & Scaffold',
      frequency: 'Before Use',
      description: 'Check stability, damage, proper tagging',
      tasks: [
        'Inspect for bent or damaged components',
        'Check all rungs/steps are secure',
        'Verify proper angle (4:1 ratio)',
        'Check locking mechanisms',
        'Inspect scaffold planking',
        'Verify guardrails are in place',
        'Check for proper tagging system',
      ],
      icon: Icons.handyman,
      color: Colors.purple,
      priority: 'MEDIUM',
    ),
    InspectionItem(
      id: 9,
      title: 'Confined Space Entry',
      frequency: 'Before Entry',
      description: 'Atmosphere testing, permits, and equipment checks',
      tasks: [
        'Test atmosphere for O₂, LEL, H₂S',
        'Check ventilation equipment',
        'Verify entry permit is valid',
        'Test communication equipment',
        'Check rescue equipment',
        'Verify attendant is present',
        'Test lighting in confined space',
      ],
      icon: Icons.door_sliding,
      color: Colors.deepPurple,
      priority: 'HIGH',
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Initialize lists
    _inspectionVisibility =
        List.generate(_inspectionItems.length, (index) => false);
    _isExpandedList = List.generate(_inspectionItems.length, (index) => false);

    // Setup animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Create staggered animations
    for (int i = 0; i < _inspectionItems.length; i++) {
      final delay = i * 120;
      final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            delay / (_inspectionItems.length * 120 + 200),
            (delay + 800) / (_inspectionItems.length * 120 + 800),
            curve: Curves.easeOutBack,
          ),
        ),
      );
      _inspectionAnimations.add(animation);
    }

    // Start animations with delay
    Future.delayed(const Duration(milliseconds: 400), () {
      _animationController.forward();
    });

    // Update visibility as animations progress
    _animationController.addListener(() {
      for (int i = 0; i < _inspectionAnimations.length; i++) {
        if (_inspectionAnimations[i].value > 0.1 && !_inspectionVisibility[i]) {
          setState(() {
            _inspectionVisibility[i] = true;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspections'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.secondary,
        elevation: 0,
      ),
      body: Container(
        color: AppColors.background,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.checklist,
                      color: Colors.blue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'INSPECTIONS GUIDE',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Essential inspection procedures for all areas',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Quick Info
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tap any inspection item to view detailed points',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Animated Inspection Items with Expansion Tiles (Points only)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _inspectionItems.length,
                itemBuilder: (context, index) {
                  final item = _inspectionItems[index];
                  final animation = _inspectionAnimations[index];

                  return AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          (1 - animation.value) * 30,
                          0,
                        ),
                        child: Opacity(
                          opacity: animation.value.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: 0.95 + (animation.value * 0.05),
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: item.color.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: item.color.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: ExpansionTile(
                        key: ValueKey(item.id),
                        initiallyExpanded: _isExpandedList[index],
                        onExpansionChanged: (expanded) {
                          setState(() {
                            _isExpandedList[index] = expanded;
                          });
                        },
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: item.color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item.icon,
                            color: item.color,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.description,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getPriorityColor(item.priority)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _getPriorityColor(item.priority)
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    item.priority,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _getPriorityColor(item.priority),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.blue.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    item.frequency,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Icon(
                          Icons.expand_more,
                          color: item.color,
                        ),
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        childrenPadding: const EdgeInsets.only(
                          left: 72,
                          right: 16,
                          bottom: 16,
                        ),
                        children: [
                          const Divider(
                            height: 1,
                            thickness: 1,
                          ),
                          const SizedBox(height: 12),
                          ...item.tasks.map((task) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: item.color,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        task,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[50],
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.amber[700],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Regular inspections prevent accidents and ensure safety compliance',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'HIGH':
        return Colors.red;
      case 'MEDIUM':
        return Colors.orange;
      case 'LOW':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class InspectionItem {
  final int id;
  final String title;
  final String frequency;
  final String description;
  final List<String> tasks;
  final IconData icon;
  final Color color;
  final String priority;

  InspectionItem({
    required this.id,
    required this.title,
    required this.frequency,
    required this.description,
    required this.tasks,
    required this.icon,
    required this.color,
    required this.priority,
  });
}
