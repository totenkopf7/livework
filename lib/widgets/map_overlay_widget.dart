import 'package:flutter/material.dart';
import '../data/models/report_model.dart';
import '../data/models/site_model.dart';

class MapOverlayWidget extends StatelessWidget {
  final SiteModel site;
  final List<ReportModel> reports;
  final Function(String) onReportSelected;

  const MapOverlayWidget({
    Key? key,
    required this.site,
    required this.reports,
    required this.onReportSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Stack(
        children: [
          // Placeholder for map
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Map View',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Site: ${site.name}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${reports.length} reports',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),

          // Report markers overlay
          ...reports.map((report) => _buildReportMarker(report)),
        ],
      ),
    );
  }

  Widget _buildReportMarker(ReportModel report) {
    // Calculate position based on report coordinates or use default
    final position = Offset(
      (report.longitude ?? site.longitude) * 100,
      (report.latitude ?? site.latitude) * 100,
    );

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onTap: () => onReportSelected(report.id),
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: _getReportColor(report),
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
            _getReportIcon(report),
            size: 12,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Color _getReportColor(ReportModel report) {
    switch (report.status) {
      case ReportStatus.inProgress:
        return Colors.orange;
      case ReportStatus.done:
        return Colors.green;
      case ReportStatus.hazard:
        return Colors.red;
    }
  }

  IconData _getReportIcon(ReportModel report) {
    switch (report.type) {
      case ReportType.work:
        return Icons.build;
      case ReportType.hazard:
        return Icons.warning;
    }
  }
}
