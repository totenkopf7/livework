import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:livework_view/widgets/colors.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../data/models/report_model.dart';
import 'package:livework_view/providers/auth_provider.dart' as livework_auth;
import 'package:livework_view/providers/site_provider.dart';
import 'package:livework_view/helpers/localization_helper.dart';
import 'dart:html' as html;

class ReportCardWidget extends StatelessWidget {
  final ReportModel report;
  final Function(ReportStatus) onStatusChanged;
  final VoidCallback? onDelete;
  final VoidCallback? onArchive;
  final VoidCallback? onUnarchive;
  final bool showDeleteButton;
  final bool showArchiveButton;
  final bool showUnarchiveButton;
  final bool showCompleteButton;
  final bool showControlledButton;
  final bool showStatusDropdown;
  final bool showEditButton;
  final VoidCallback? onEdit;

  const ReportCardWidget({
    Key? key,
    required this.report,
    required this.onStatusChanged,
    this.onDelete,
    this.onArchive,
    this.onUnarchive,
    this.showDeleteButton = false,
    this.showArchiveButton = false,
    this.showUnarchiveButton = false,
    this.showCompleteButton = false,
    this.showControlledButton = false,
    this.showStatusDropdown = false,
    this.showEditButton = false,
    this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider =
        Provider.of<livework_auth.LiveWorkAuthProvider>(context);
    final isAdmin = authProvider.isAdmin;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (report.isArchived) ...[
                  Icon(
                    Icons.archive,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                ],
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
                      Consumer<SiteProvider>(
                        builder: (context, siteProvider, child) {
                          return Text(
                            siteProvider.getZoneName(context, report.zone),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                      Text(
                        _getStatusText(context, report.status),
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
                    report.type == ReportType.work
                        ? translate(context, 'work').toUpperCase()
                        : translate(context, 'hazard').toUpperCase(),
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
            SelectableText(
              report.description,
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${translate(context, 'Created on')}: ${_formatDate(report.timestamp)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                if (report.reporterName != null) ...[
                  Icon(
                    Icons.engineering,
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
            // REMOVED: Archive date display since we only need creation date
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
            if (isAdmin) ...[
              const SizedBox(height: 12),

              // UPDATED: REORGANIZED ACTION BUTTONS TO BE SIDE-BY-SIDE WHEN APPROPRIATE
              _buildActionButtonsRow(context),

              if (showStatusDropdown && !report.isArchived)
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<ReportStatus>(
                        value: report.status,
                        decoration: InputDecoration(
                          labelText: translate(context, 'status'),
                          border: OutlineInputBorder(),
                        ),
                        items: ReportStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(_getStatusText(context, status)),
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
                      tooltip: translate(context, 'view_location_tooltip'),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  // UPDATED: NEW METHOD TO ORGANIZE ACTION BUTTONS IN A ROW INSTEAD OF FULL WIDTH STACK
  Widget _buildActionButtonsRow(BuildContext context) {
    List<Widget> actionButtons = [];

    // ADD EDIT BUTTON IF ENABLED
    if (showEditButton && onEdit != null) {
      actionButtons.add(
        Expanded(
          child: _buildCompactActionButton(
            context,
            icon: Icons.edit,
            text: translate(context, 'edit_report'),
            color: Colors.blue,
            onPressed: onEdit!,
          ),
        ),
      );
    }

    // ADD COMPLETE/CONTROLLED BUTTONS
    if (showCompleteButton && report.type == ReportType.work) {
      if (actionButtons.isNotEmpty) actionButtons.add(const SizedBox(width: 8));
      actionButtons.add(
        Expanded(
          child: _buildCompactActionButton(
            context,
            icon: Icons.check,
            text: translate(context, 'tap_if_completed'),
            color: Colors.green,
            onPressed: () {
              onStatusChanged(ReportStatus.done);
            },
          ),
        ),
      );
    }

    if (showControlledButton && report.type == ReportType.hazard) {
      if (actionButtons.isNotEmpty) actionButtons.add(const SizedBox(width: 8));
      actionButtons.add(
        Expanded(
          child: _buildCompactActionButton(
            context,
            icon: Icons.security,
            text: translate(context, 'tap_if_controlled'),
            color: Colors.blue,
            onPressed: () {
              onStatusChanged(ReportStatus.done);
            },
          ),
        ),
      );
    }

    // ADD ARCHIVE/UNARCHIVE BUTTONS (STAY FULL WIDTH SINCE THEY ARE DESTRUCTIVE ACTIONS)
    if (showArchiveButton && onArchive != null) {
      if (actionButtons.isNotEmpty) {
        // If we have row buttons above, add spacing
        actionButtons.add(const SizedBox(height: 8));
      }
      actionButtons.add(
        _buildActionButton(
          context,
          icon: Icons.archive,
          text: translate(context, 'archive_report'),
          color: Colors.orange,
          onPressed: onArchive!,
        ),
      );
    }

    if (showUnarchiveButton && onUnarchive != null) {
      if (actionButtons.isNotEmpty) {
        actionButtons.add(const SizedBox(height: 8));
      }
      actionButtons.add(
        _buildActionButton(
          context,
          icon: Icons.unarchive,
          text: translate(context, 'unarchive_report'),
          color: Colors.green,
          onPressed: onUnarchive!,
        ),
      );
    }

    // ADD DELETE BUTTON (STAY FULL WIDTH SINCE IT'S DESTRUCTIVE)
    if (showDeleteButton && onDelete != null) {
      if (actionButtons.isNotEmpty) {
        actionButtons.add(const SizedBox(height: 8));
      }
      actionButtons.add(
        _buildActionButton(
          context,
          icon: Icons.delete,
          text: translate(context, 'delete_report'),
          color: Colors.red,
          onPressed: onDelete!,
        ),
      );
    }

    // RETURN COLUMN WITH POTENTIAL ROW FOR SIDE-BY-SIDE BUTTONS
    return Column(
      children: [
        // ROW FOR EDIT/COMPLETE/CONTROLLED BUTTONS
        if (showEditButton || showCompleteButton || showControlledButton)
          Row(
            children: actionButtons
                .where((button) => button is Expanded)
                .cast<Widget>()
                .toList(),
          ),

        // FULL WIDTH BUTTONS FOR ARCHIVE/UNARCHIVE/DELETE
        ...actionButtons.where((button) => button is! Expanded).toList(),
      ],
    );
  }

  // UPDATED: COMPACT VERSION OF ACTION BUTTON FOR SIDE-BY-SIDE LAYOUT
  Widget _buildCompactActionButton(
    BuildContext context, {
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(
          text,
          style: TextStyle(fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        ),
      ),
    );
  }

  // ORIGINAL FULL WIDTH BUTTON FOR ARCHIVE/DELETE ACTIONS
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

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

  void _showFullImage(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(translate(context, 'image')),
              backgroundColor: AppColors.background,
              foregroundColor: AppColors.secondary,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Flexible(
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 600,
                  maxHeight: 600,
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
            SnackBar(content: Text(translate(context, 'permission_denied'))),
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
          SnackBar(content: Text(translate(context, 'image_saved'))),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${translate(context, 'failed_to_save_image')}: $e')),
      );
    }
  }

  void _showLocationInfo(BuildContext context) {
    if (report.latitude != null && report.longitude != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(translate(context, 'location_information')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  '${translate(context, 'type')}: ${report.type == ReportType.work ? translate(context, 'work') : translate(context, 'hazard')}'),
              Text(
                  '${translate(context, 'status')}: ${_getStatusText(context, report.status)}'),
              Consumer<SiteProvider>(
                builder: (context, siteProvider, child) {
                  return Text(
                      '${translate(context, 'zone')}: ${siteProvider.getZoneName(context, report.zone)}');
                },
              ),
              Text(
                  '${translate(context, 'description')}: ${report.description}'),
              if (report.mapX != null && report.mapY != null) ...[
                const SizedBox(height: 8),
                Text(
                    '${translate(context, 'map_location')}: ${(report.mapX! * 100).toStringAsFixed(1)}%, ${(report.mapY! * 100).toStringAsFixed(1)}%'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(translate(context, 'close')),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(translate(context, 'no_location_data')),
        ),
      );
    }
  }

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

  String _getStatusText(BuildContext context, ReportStatus status) {
    switch (status) {
      case ReportStatus.inProgress:
        return translate(context, 'in_progress');
      case ReportStatus.done:
        return translate(context, 'completed');
      case ReportStatus.hazard:
        return translate(context, 'hazard');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
