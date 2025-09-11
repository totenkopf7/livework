import 'package:flutter/material.dart';

class CustomMapWidget extends StatefulWidget {
  final Function(double x, double y) onLocationSelected;
  final List<MapMarker> markers;
  final String mapImagePath;
  final void Function(MapMarker)? onMarkerTap;

  const CustomMapWidget({
    Key? key,
    required this.onLocationSelected,
    this.markers = const [],
    this.mapImagePath = 'assets/images/company_map.png',
    this.onMarkerTap,
  }) : super(key: key);

  @override
  State<CustomMapWidget> createState() => _CustomMapWidgetState();
}

class _CustomMapWidgetState extends State<CustomMapWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: GestureDetector(
          onTapDown: (details) {
            final RenderBox renderBox = context.findRenderObject() as RenderBox;
            final localPosition = renderBox.globalToLocal(details.globalPosition);
            final size = renderBox.size;

            // Convert to percentage coordinates (0.0 to 1.0)
            final x = (localPosition.dx / size.width).clamp(0.0, 1.0);
            final y = (localPosition.dy / size.height).clamp(0.0, 1.0);

            widget.onLocationSelected(x, y);
          },
          child: Stack(
            children: [
              // Fallback map container with gradient background
              AspectRatio(
                aspectRatio: 4 / 3,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.blue.shade100, Colors.green.shade100],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map,
                          size: 64,
                          color: Colors.blue.shade600,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Company Map',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap to select location',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Markers overlay
              ...widget.markers.map((marker) => _buildMarker(marker)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarker(MapMarker marker) {
    return Positioned(
      left: marker.x * (MediaQuery.of(context).size.width - 24),
      top: marker.y * (MediaQuery.of(context).size.width * 0.75) - 12,
      child: GestureDetector(
        onTap: () {
          if (widget.onMarkerTap != null) {
            widget.onMarkerTap!(marker);
          }
        },
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: marker.color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            marker.icon,
            size: 12,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class MapMarker {
  final double x;
  final double y;
  final Color color;
  final IconData icon;
  final String label;

  MapMarker({
    required this.x,
    required this.y,
    required this.color,
    required this.icon,
    required this.label,
  });
}