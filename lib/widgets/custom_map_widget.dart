import 'package:flutter/material.dart';

class CustomMapWidget extends StatefulWidget {
  final Function(double x, double y) onLocationSelected;
  final List<MapMarker> markers;
  final String mapImagePath;
  final void Function(MapMarker)? onMarkerTap; // NEW

  const CustomMapWidget({
    Key? key,
    required this.onLocationSelected,
    this.markers = const [],
    this.mapImagePath = 'assets/images/company_map.png',
    this.onMarkerTap, // NEW
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
            final localPosition =
                renderBox.globalToLocal(details.globalPosition);
            final size = renderBox.size;

            // Convert to percentage coordinates (0.0 to 1.0)
            final x = localPosition.dx / size.width;
            final y = localPosition.dy / size.height;

            widget.onLocationSelected(x, y);
          },
          child: Stack(
            children: [
              // Company map image
              AspectRatio(
                aspectRatio: 4 / 3, // Adjust this ratio to match your map image
                child: Image.asset(
                  widget.mapImagePath,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    print('Map image failed to load: $error');
                    print('Attempted path: ${widget.mapImagePath}');
                    return Container(
                      width: double.infinity,
                      height: 300,
                      color: Colors.blue[50],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map,
                            size: 64,
                            color: Colors.blue[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Company Map',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.blue[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to select location',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue[500],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Map image not found at:\n${widget.mapImagePath}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Error: $error',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              // TODO: Add option to upload custom map
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Please add your company map to assets/images/company_map.png'),
                                ),
                              );
                            },
                            child: const Text('Upload Map'),
                          ),
                        ],
                      ),
                    );
                  },
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
