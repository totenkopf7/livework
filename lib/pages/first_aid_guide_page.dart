import 'package:flutter/material.dart';
import 'package:livework_view/widgets/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class FirstAidGuidePage extends StatefulWidget {
  const FirstAidGuidePage({Key? key}) : super(key: key);

  @override
  _FirstAidGuidePageState createState() => _FirstAidGuidePageState();
}

class _FirstAidGuidePageState extends State<FirstAidGuidePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  List<bool> _guideVisibility = [];
  List<Animation<double>> _guideAnimations = [];
  List<bool> _isExpandedList = [];

  final List<FirstAidItem> _firstAidProcedures = [
    FirstAidItem(
      id: 1,
      title: 'Emergency Response',
      description: 'Call emergency services immediately for serious injuries',
      details: [
        'Dial emergency number (066122)',
        'Provide clear location information',
        'Describe the nature of injury',
        'Follow dispatcher instructions',
        'Stay on the line until help arrives',
      ],
      icon: Icons.call,
      color: Colors.red,
      urgency: 'HIGH',
    ),
    FirstAidItem(
      id: 2,
      title: 'Bleeding Control',
      description: 'Stop bleeding by applying direct pressure',
      details: [
        'Wear gloves before treating any wound',
        'Apply direct pressure with clean cloth',
        'Elevate injured limb if possible',
        'Apply pressure bandage',
        'Monitor for signs of shock',
      ],
      icon: Icons.healing,
      color: Colors.deepOrange,
      urgency: 'HIGH',
    ),
    FirstAidItem(
      id: 3,
      title: 'Chemical Exposure',
      description: 'Flush chemical splashes with plenty of water',
      details: [
        'Eyes: Flush for at least 15 minutes',
        'Skin: Remove contaminated clothing',
        'Irrigate with copious amounts of water',
        'Identify chemical if possible',
        'Seek medical attention immediately',
      ],
      icon: Icons.science,
      color: Colors.purple,
      urgency: 'HIGH',
    ),
    FirstAidItem(
      id: 4,
      title: 'Burn Treatment',
      description: 'Use appropriate treatment for thermal or chemical burns',
      details: [
        'Cool with running water for 10-20 minutes',
        'Cover with sterile non-stick dressing',
        'Do not apply creams or ointments',
        'Remove jewelry from affected area',
        'Treat for shock if severe',
      ],
      icon: Icons.whatshot,
      color: Colors.orange,
      urgency: 'MEDIUM',
    ),
    FirstAidItem(
      id: 5,
      title: 'H₂S Exposure',
      description: 'Immediate response for hydrogen sulfide exposure',
      details: [
        'Move person to fresh air immediately',
        'Call emergency services',
        'Administer oxygen if trained',
        'Monitor breathing closely',
        'Be prepared for CPR',
      ],
      icon: Icons.cloud,
      color: Colors.brown,
      urgency: 'HIGH',
    ),
    FirstAidItem(
      id: 6,
      title: 'CPR Procedures',
      description: 'Perform CPR if person is unresponsive',
      details: [
        'Check responsiveness and breathing',
        'Call for AED if available',
        '30 chest compressions, 2 breaths',
        'Continue until help arrives',
        'Use proper protective equipment',
      ],
      icon: Icons.medical_services,
      color: Colors.redAccent,
      urgency: 'HIGH',
    ),
    FirstAidItem(
      id: 7,
      title: 'Heat-Related Illness',
      description: 'Treatment for heat exhaustion and heat stroke',
      details: [
        'Move to cool, shaded area',
        'Remove excess clothing',
        'Apply cool compresses',
        'Hydrate with water',
        'Monitor vital signs',
      ],
      icon: Icons.wb_sunny,
      color: Colors.amber,
      urgency: 'MEDIUM',
    ),
    FirstAidItem(
      id: 8,
      title: 'Fracture Management',
      description: 'Immobilize suspected fractures',
      details: [
        'Do not move injured limb unnecessarily',
        'Apply splint if available',
        'Elevate if no spinal injury suspected',
        'Apply ice packs to reduce swelling',
        'Seek medical attention',
      ],
      icon: Icons.accessibility_new,
      color: Colors.blueGrey,
      urgency: 'MEDIUM',
    ),
    FirstAidItem(
      id: 9,
      title: 'Shock Treatment',
      description: 'Recognize and treat for shock',
      details: [
        'Keep person lying down',
        'Elevate legs if no spinal injury',
        'Loosen tight clothing',
        'Keep person warm',
        'Monitor breathing and pulse',
      ],
      icon: Icons.health_and_safety,
      color: Colors.teal,
      urgency: 'HIGH',
    ),
    FirstAidItem(
      id: 10,
      title: 'First Aid Kit Use',
      description: 'Proper use of first aid supplies',
      details: [
        'Check kit contents regularly',
        'Restock after every use',
        'Use items before expiration date',
        'Keep kits accessible',
        'Train staff on kit location',
      ],
      icon: Icons.medical_information,
      color: Colors.green,
      urgency: 'LOW',
    ),
  ];

  @override
  void initState() {
    super.initState();

    _guideVisibility =
        List.generate(_firstAidProcedures.length, (index) => false);
    _isExpandedList =
        List.generate(_firstAidProcedures.length, (index) => false);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Create staggered animations
    for (int i = 0; i < _firstAidProcedures.length; i++) {
      final delay = i * 150;
      final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            delay / (_firstAidProcedures.length * 150 + 200),
            (delay + 800) / (_firstAidProcedures.length * 150 + 800),
            curve: Curves.easeOutBack,
          ),
        ),
      );
      _guideAnimations.add(animation);
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      _animationController.forward();
    });

    _animationController.addListener(() {
      for (int i = 0; i < _guideAnimations.length; i++) {
        if (_guideAnimations[i].value > 0.1 && !_guideVisibility[i]) {
          setState(() {
            _guideVisibility[i] = true;
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

  void _showFirstAidImage(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'First Aid Reference',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.background,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/first_aid.jpeg'),
                      fit: BoxFit.contain,
                    ),
                  ),
                  margin: const EdgeInsets.all(16),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'First aid procedures for common refinery injuries',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchFirstAidVideo() async {
    const url = 'https://www.youtube.com/watch?v=7XClM6OT2uA';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open video'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.red, // <-- change back arrow color
        ),
        title: const Text('First Aid Guide'),
        backgroundColor: Colors.red.shade50,
        foregroundColor: Colors.red.shade900,
        elevation: 0,
      ),
      body: Container(
        color: Colors.red.shade50,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade100, Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.red.shade200!,
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
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.medical_services,
                      color: Colors.red,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FIRST AID GUIDE',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Emergency procedures for refinery injuries',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
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

            SizedBox(height: 8),

            // Quick Action Buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(
                    icon: Icons.photo_library,
                    label: 'Visual Guide',
                    color: Colors.blue,
                    onTap: () => _showFirstAidImage(context),
                  ),
                  _ActionButton(
                    icon: Icons.video_library,
                    label: 'Video',
                    color: Colors.red,
                    onTap: _launchFirstAidVideo,
                  ),
                ],
              ),
            ),

            // Animated First Aid Procedures with Expansion Tiles
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _firstAidProcedures.length,
                itemBuilder: (context, index) {
                  final procedure = _firstAidProcedures[index];
                  final animation = _guideAnimations[index];

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
                            color: procedure.color.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: procedure.color.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: ExpansionTile(
                        key: ValueKey(procedure.id),
                        initiallyExpanded: _isExpandedList[index],
                        onExpansionChanged: (expanded) {
                          setState(() {
                            _isExpandedList[index] = expanded;
                          });
                        },
                        leading: Stack(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: procedure.color.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                procedure.icon,
                                color: procedure.color,
                                size: 22,
                              ),
                            ),
                            if (procedure.urgency == 'HIGH')
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Text(
                          procedure.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: procedure.color,
                          ),
                        ),
                        subtitle: Text(
                          procedure.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getUrgencyColor(procedure.urgency)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: _getUrgencyColor(procedure.urgency)
                                  .withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            procedure.urgency,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _getUrgencyColor(procedure.urgency),
                            ),
                          ),
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
                          ...procedure.details.map((detail) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: procedure.color,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        detail,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: procedure.color.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: procedure.color.withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: procedure.color,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Report all injuries to supervisor immediately',
                                    style: TextStyle(
                                      fontSize: 12,
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
                    Icons.warning_amber,
                    color: Colors.amber[700],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'For life-threatening emergencies, call emergency services immediately',
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

  Color _getUrgencyColor(String urgency) {
    switch (urgency) {
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FirstAidItem {
  final int id;
  final String title;
  final String description;
  final List<String> details;
  final IconData icon;
  final Color color;
  final String urgency;

  FirstAidItem({
    required this.id,
    required this.title,
    required this.description,
    required this.details,
    required this.icon,
    required this.color,
    required this.urgency,
  });
}
