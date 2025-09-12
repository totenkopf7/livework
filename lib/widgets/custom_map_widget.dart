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
  bool _isImageLoading = true;
  bool _imageError = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // Company map image
            AspectRatio(
              aspectRatio: 4 / 3,
              child: _isImageLoading
                  ? const Center(child: CircularProgressIndicator())
                  : (_imageError
                      ? _buildFallbackMap()
                      : Image.asset(
                          widget.mapImagePath,
                          width: double.infinity,
                          fit: BoxFit.contain,
                        )),
            ),
            // Markers overlay
            ...widget.markers.map((marker) => _buildMarker(marker)),
            // Tap detector overlay
            Positioned.fill(
              child: GestureDetector(
                onTapDown: (details) {
                  final RenderBox renderBox =
                      context.findRenderObject() as RenderBox;
                  final localPosition =
                      renderBox.globalToLocal(details.globalPosition);
                  final size = renderBox.size;

                  // Convert to percentage coordinates (0.0 to 1.0)
                  final x = (localPosition.dx / size.width).clamp(0.0, 1.0);
                  final y = (localPosition.dy / size.height).clamp(0.0, 1.0);

                  widget.onLocationSelected(x, y);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Preload the image
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      // Use precacheImage to load the image and handle errors
      await precacheImage(
        AssetImage(widget.mapImagePath),
        context,
        onError: (exception, stackTrace) {
          if (mounted) {
            setState(() {
              _isImageLoading = false;
              _imageError = true;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isImageLoading = false;
          _imageError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isImageLoading = false;
          _imageError = true;
        });
      }
    }
  }

  Widget _buildFallbackMap() {
    return Container(
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
            const SizedBox(height: 8),
            Text(
              'Image not found at:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              widget.mapImagePath,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
            size: 8,
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
