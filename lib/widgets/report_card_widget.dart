import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:livework_view/widgets/colors.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/models/report_model.dart';
// For web download
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class ReportCardWidget extends StatelessWidget {
  final ReportModel report;
  final Function(ReportStatus) onStatusChanged;
  final VoidCallback? onDelete;
  final bool showDeleteButton;

  const ReportCardWidget({
    Key? key,
    required this.report,
    required this.onStatusChanged,
    this.onDelete,
    this.showDeleteButton = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row with icon and info
            Row(
              children: [
                Icon(
                  _getReportIcon(report.type),
                  color: _getStatusColor(report.status),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.zone,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getStatusText(report.status),
                        style: TextStyle(
                          fontSize: 14,
                          color: _getStatusColor(report.status),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    report.type.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: report.type == ReportType.work
                      ? Colors.blue.shade100
                      : Colors.red.shade100,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              report.description,
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 12),
            // Timestamp and reporter
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(report.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                if (report.reporterName != null) ...[
                  Icon(
                    Icons.person,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    report.reporterName!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
            // Images
            if (report.photoUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: report.photoUrls.length,
                  itemBuilder: (context, index) {
                    final imagePath = report.photoUrls[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _showFullImage(context, imagePath),
                        onLongPress: () => _saveImage(context, imagePath),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 100,
                            height: 100,
                            child: kIsWeb
                                ? _buildWebImage(imagePath)
                                : _buildMobileImage(imagePath),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            // Status button
            if (report.status == ReportStatus.inProgress) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => onStatusChanged(ReportStatus.done),
                icon: const Icon(Icons.check),
                label: const Text('Tap if completed'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:AppColors.background,
                  foregroundColor: AppColors.secondary,
                ),
              ),
            ],
            // Delete button
            if (showDeleteButton && onDelete != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ElevatedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Delete Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Status dropdown
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<ReportStatus>(
                    value: report.status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: ReportStatus.values.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(_getStatusText(status)),
                      );
                    }).toList(),
                    onChanged: (newStatus) {
                      if (newStatus != null) {
                        onStatusChanged(newStatus);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => _showLocationInfo(context),
                  icon: const Icon(Icons.location_on),
                  tooltip: 'View Location',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ----- IMAGE BUILDERS -----
  Widget _buildWebImage(String imagePath) {
    if (imagePath.startsWith('data:image')) {
      return Image.memory(
        base64Decode(imagePath.split(',')[1]),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _placeholderImage(),
      );
    } else {
      return _placeholderImage();
    }
  }

  Widget _buildMobileImage(String imagePath) {
    return Image.file(
      File(imagePath),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _placeholderImage(),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[300],
      child: const Icon(
        Icons.image,
        color: Colors.grey,
      ),
    );
  }

  // ----- FULL IMAGE VIEW -----
  void _showFullImage(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Image'),
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Flexible(
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 400,
                  maxHeight: 400,
                ),
                child: kIsWeb
                    ? _buildWebImage(imagePath)
                    : _buildMobileImage(imagePath),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----- SAVE IMAGE -----
  void _saveImage(BuildContext context, String imagePath) async {
    try {
      if (kIsWeb) {
        final bytes = base64Decode(imagePath.split(',')[1]);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", "report_image.png")
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission denied')),
          );
          return;
        }

        final bytes = await File(imagePath).readAsBytes();
        await ImageGallerySaver.saveImage(
          bytes,
          quality: 100,
          name: "report_${DateTime.now().millisecondsSinceEpoch}",
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image saved to gallery!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save image: $e')),
      );
    }
  }

  // ----- LOCATION INFO -----
  void _showLocationInfo(BuildContext context) {
    if (report.latitude != null && report.longitude != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Location Information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Type: ${report.type.name}'),
              Text('Status: ${report.status.name}'),
              Text('Zone: ${report.zone}'),
              Text('Description: ${report.description}'),
              if (report.mapX != null && report.mapY != null) ...[
                const SizedBox(height: 8),
                Text(
                    'Map Location: ${(report.mapX! * 100).toStringAsFixed(1)}%, ${(report.mapY! * 100).toStringAsFixed(1)}%'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No location data available for this report'),
        ),
      );
    }
  }

  // ----- HELPER METHODS -----
  IconData _getReportIcon(ReportType type) {
    switch (type) {
      case ReportType.work:
        return Icons.build;
      case ReportType.hazard:
        return Icons.warning;
    }
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.inProgress:
        return Colors.orange;
      case ReportStatus.done:
        return Colors.green;
      case ReportStatus.hazard:
        return Colors.red;
    }
  }

  String _getStatusText(ReportStatus status) {
    switch (status) {
      case ReportStatus.inProgress:
        return 'In Progress';
      case ReportStatus.done:
        return 'Completed';
      case ReportStatus.hazard:
        return 'Hazard';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
