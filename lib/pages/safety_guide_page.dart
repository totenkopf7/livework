import 'package:flutter/material.dart';
import 'package:livework_view/widgets/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class SafetyGuidePage extends StatefulWidget {
  const SafetyGuidePage({Key? key}) : super(key: key);

  @override
  _SafetyGuidePageState createState() => _SafetyGuidePageState();
}

class _SafetyGuidePageState extends State<SafetyGuidePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  List<bool> _guideVisibility = [];
  List<Animation<double>> _guideAnimations = [];

  final List<SafetyGuideItem> _safetyGuides = [
    SafetyGuideItem(
      id: 1,
      title: 'Personal Protective Equipment (PPE)',
      description: 'Always wear the required PPE for your task',
      details: [
        'Wear hard hats in designated areas',
        'Use safety glasses/goggles for eye protection',
        'Wear appropriate gloves for the task',
        'Use hearing protection in high-noise areas',
        'Wear steel-toe boots at all times',
      ],
      icon: Icons.work,
      color: Colors.blue,
    ),
    SafetyGuideItem(
      id: 2,
      title: 'Refinery Safety Procedures',
      description: 'Follow all refinery safety procedures and permits',
      details: [
        'Obtain proper permits before starting work',
        'Attend safety meetings and briefings',
        'Follow lockout/tagout procedures',
        'Comply with confined space entry requirements',
        'Adhere to hot work permit guidelines',
      ],
      icon: Icons.security,
      color: Colors.green,
    ),
    SafetyGuideItem(
      id: 3,
      title: 'Hazard Reporting',
      description: 'Report unsafe conditions immediately',
      details: [
        'Report leaks and spills immediately',
        'Notify about strange smells or odors',
        'Report abnormal sounds or vibrations',
        'Identify and report tripping hazards',
        'Report equipment malfunctions',
      ],
      icon: Icons.warning,
      color: Colors.orange,
    ),
    SafetyGuideItem(
      id: 4,
      title: 'Housekeeping',
      description: 'Maintain good housekeeping to prevent accidents',
      details: [
        'Keep work areas clean and organized',
        'Store tools and materials properly',
        'Clean spills immediately',
        'Remove waste and debris regularly',
        'Keep emergency exits clear',
      ],
      icon: Icons.cleaning_services,
      color: Colors.purple,
    ),
    SafetyGuideItem(
      id: 5,
      title: 'Confined Space Safety',
      description: 'Never enter confined spaces without proper procedures',
      details: [
        'Test atmosphere before entry',
        'Ensure adequate ventilation',
        'Have proper permits and training',
        'Always have an attendant present',
        'Use appropriate rescue equipment',
      ],
      icon: Icons.door_sliding,
      color: Colors.red,
    ),
    SafetyGuideItem(
      id: 6,
      title: 'Tool and Equipment Safety',
      description: 'Use tools and equipment only if trained and authorized',
      details: [
        'Inspect tools before use',
        'Use tools only for intended purposes',
        'Report damaged equipment immediately',
        'Follow manufacturer instructions',
        'Store tools properly after use',
      ],
      icon: Icons.build,
      color: Colors.brown,
    ),
    SafetyGuideItem(
      id: 7,
      title: 'Gas Hazard Awareness',
      description: 'Check for gas hazards before starting work',
      details: [
        'Test for H₂S and LEL regularly',
        'Use gas detectors properly',
        'Know emergency procedures for gas leaks',
        'Wear appropriate respiratory protection',
        'Evacuate immediately if alarms sound',
      ],
      icon: Icons.cloud,
      color: Colors.teal,
    ),
    SafetyGuideItem(
      id: 8,
      title: 'Emergency Response',
      description: 'Know emergency procedures and escape routes',
      details: [
        'Know location of emergency alarms',
        'Identify primary and secondary escape routes',
        'Know muster point locations',
        'Understand fire response procedures',
        'Know gas release response protocols',
      ],
      icon: Icons.emergency,
      color: Colors.redAccent,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _guideVisibility = List.generate(_safetyGuides.length, (index) => false);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Create staggered animations
    for (int i = 0; i < _safetyGuides.length; i++) {
      final delay = i * 150; // 150ms delay between each item
      final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            delay / (_safetyGuides.length * 150 + 200),
            (delay + 800) / (_safetyGuides.length * 150 + 800),
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

  void _showSafetyTools(BuildContext context) {
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
                      'Safety Tools Reference',
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
                child: InteractiveViewer(
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 0.1,
                  maxScale: 10.0,
                  panEnabled: true,
                  scaleEnabled: true,
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                        image: const DecorationImage(
                          image: AssetImage('assets/images/safety_tools.jpg'),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.touch_app,
                      size: 16,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Pinch to zoom • Drag to pan',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.rotate_90_degrees_ccw,
                      size: 16,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Rotate with two fingers',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchSafetyVideo() async {
    const url = 'https://www.youtube.com/watch?v=bjlAUBNs93Y';
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
        title: const Text('Safety Guide'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.secondary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('About Safety Guide'),
                  content: const Text(
                    'This guide provides essential safety procedures for refinery operations. '
                    'Always follow these guidelines and report any safety concerns immediately.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
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
                    child: Icon(
                      Icons.security,
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
                          'SAFETY GUIDE',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Essential safety procedures for refinery operations',
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

            SizedBox(height: 8),

            // Quick Action Buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.grey[50],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(
                    icon: Icons.photo_library,
                    label: 'Tools',
                    color: Colors.green,
                    onTap: () => _showSafetyTools(context),
                  ),
                  _ActionButton(
                    icon: Icons.video_library,
                    label: 'Video',
                    color: Colors.red,
                    onTap: _launchSafetyVideo,
                  ),
                  // _ActionButton(
                  //   icon: Icons.download,
                  //   label: 'PDF',
                  //   color: Colors.blue,
                  //   onTap: () {
                  //     ScaffoldMessenger.of(context).showSnackBar(
                  //       const SnackBar(
                  //         content: Text('Safety guide PDF downloaded'),
                  //         backgroundColor: Colors.green,
                  //       ),
                  //     );
                  //   },
                  // ),
                ],
              ),
            ),

            // Animated Safety Guides List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _safetyGuides.length,
                itemBuilder: (context, index) {
                  final guide = _safetyGuides[index];
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
                            color: guide.color.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: guide.color.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: ExpansionTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: guide.color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            guide.icon,
                            color: guide.color,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          guide.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          guide.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                        trailing: Icon(
                          Icons.expand_more,
                          color: guide.color,
                        ),
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        childrenPadding: const EdgeInsets.only(
                          left: 72,
                          right: 16,
                          bottom: 16,
                        ),
                        children: [
                          ...guide.details.map((detail) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: guide.color,
                                    ),
                                    const SizedBox(width: 8),
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
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Footer
            // Container(
            //   padding: const EdgeInsets.all(16),
            //   color: Colors.grey[50],
            //   child: Row(
            //     children: [
            //       Icon(
            //         Icons.lightbulb_outline,
            //         color: Colors.amber[700],
            //         size: 20,
            //       ),
            //       const SizedBox(width: 12),
            //       // Expanded(
            //       //   child: Text(
            //       //     'Safety first! Always follow procedures and report concerns.',
            //       //     style: TextStyle(
            //       //       fontSize: 13,
            //       //       color: Colors.grey[700],
            //       //       fontStyle: FontStyle.italic,
            //       //     ),
            //       //   ),
            //       // ),
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
    );
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

class SafetyGuideItem {
  final int id;
  final String title;
  final String description;
  final List<String> details;
  final IconData icon;
  final Color color;

  SafetyGuideItem({
    required this.id,
    required this.title,
    required this.description,
    required this.details,
    required this.icon,
    required this.color,
  });
}
