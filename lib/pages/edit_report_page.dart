import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:livework_view/widgets/colors.dart';
import 'package:livework_view/providers/report_provider.dart';
import 'package:livework_view/providers/site_provider.dart';
import 'package:livework_view/data/models/report_model.dart';
import 'package:livework_view/helpers/localization_helper.dart';
import 'package:livework_view/widgets/custom_map_widget.dart'; // For map functionality

class EditReportPage extends StatefulWidget {
  final ReportModel report;

  const EditReportPage({Key? key, required this.report}) : super(key: key);

  @override
  _EditReportPageState createState() => _EditReportPageState();
}

class _EditReportPageState extends State<EditReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();

  ReportType _selectedType = ReportType.work;
  String _selectedZone = '';

  // IMAGE MANAGEMENT: Track existing, new, and removed images
  List<String> _existingPhotoUrls = []; // Original images from report
  List<XFile> _newImages = []; // Newly added images
  List<String> _removedPhotoUrls = []; // URLs of images to remove
  List<String> _tempPhotoUrls = []; // Working copy for display

  bool _isSubmitting = false;
  double? _mapX;
  double? _mapY;

  @override
  void initState() {
    super.initState();
    // Initialize with existing report data
    _descriptionController.text = widget.report.description;
    _selectedType = widget.report.type;
    _selectedZone = widget.report.zone;
    _existingPhotoUrls = List.from(widget.report.photoUrls);
    _tempPhotoUrls = List.from(widget.report.photoUrls); // Working copy
    _mapX = widget.report.mapX;
    _mapY = widget.report.mapY;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // IMAGE PICKING METHODS
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        setState(() {
          _newImages.add(image);
          _tempPhotoUrls
              .add('temp://${image.name}'); // Temporary identifier for UI
        });
      }
    } catch (e) {
      _showError('Error taking photo: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        setState(() {
          _newImages.add(image);
          _tempPhotoUrls.add('temp://${image.name}');
        });
      }
    } catch (e) {
      _showError('Error picking image: $e');
    }
  }

  // IMAGE REMOVAL METHODS
  void _removeExistingImage(int index) {
    setState(() {
      final removedUrl = _existingPhotoUrls[index];
      _existingPhotoUrls.removeAt(index);
      _tempPhotoUrls.remove(removedUrl);
      _removedPhotoUrls.add(removedUrl); // Track for deletion
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      final tempUrl = _tempPhotoUrls[_existingPhotoUrls.length + index];
      _newImages.removeAt(index);
      _tempPhotoUrls.remove(tempUrl);
    });
  }

  // IMAGE COMPRESSION (Reuse your existing logic)
  Future<Uint8List> _compressImage(XFile imageFile,
      {int maxSizeKB = 200}) async {
    try {
      final bytes = await imageFile.readAsBytes();
      if (bytes.lengthInBytes <= maxSizeKB * 1024) return bytes;

      // Your existing compression logic here
      // ... (copy from report_creation_page.dart)

      return bytes; // Fallback
    } catch (e) {
      print('Image compression error: $e');
      return await imageFile.readAsBytes();
    }
  }

  // PROCESS IMAGES FOR UPLOAD
  Future<List<String>> _processImages() async {
    List<String> finalPhotoUrls = List.from(_existingPhotoUrls);

    // Process new images
    for (int i = 0; i < _newImages.length; i++) {
      try {
        final image = _newImages[i];
        String imageUrl;

        if (kIsWeb) {
          // Web: Convert to base64
          final compressedBytes = await _compressImage(image, maxSizeKB: 200);
          final base64String = base64Encode(compressedBytes);
          imageUrl = 'data:image/jpeg;base64,$base64String';
        } else {
          // Mobile: Save to temp file
          final compressedBytes = await _compressImage(image, maxSizeKB: 200);
          final tempDir = Directory.systemTemp;
          final tempFile = File(
              '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
          await tempFile.writeAsBytes(compressedBytes);
          imageUrl = tempFile.path;
        }

        finalPhotoUrls.add(imageUrl);
      } catch (e) {
        print('Error processing new image $i: $e');
        // Continue with other images even if one fails
      }
    }

    return finalPhotoUrls;
  }

  // MAIN EDIT SUBMISSION
  Future<void> _submitEdit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;

    setState(() => _isSubmitting = true);

    try {
      final reportProvider =
          Provider.of<ReportProvider>(context, listen: false);
      final siteProvider = Provider.of<SiteProvider>(context, listen: false);

      if (siteProvider.currentSite == null) {
        _showError(translate(context, 'no_site_selected'));
        return;
      }

      // Process images (existing + new - removed)
      final updatedPhotoUrls = await _processImages();

      // Update the report
      await reportProvider.editReport(
        reportId: widget.report.id,
        description: _descriptionController.text.trim(),
        zone: _selectedZone,
        type: _selectedType,
        photoUrls: updatedPhotoUrls,
        mapX: _mapX,
        mapY: _mapY,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translate(context, 'report_updated'))),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _showError('Error updating report: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // IMAGE DISPLAY WIDGET
  Widget _buildImagePreview(String imageUrl, int index, bool isExisting) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[300],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildImageWidget(imageUrl),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => isExisting
                  ? _removeExistingImage(index)
                  : _removeNewImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
          if (!isExisting) // Show "NEW" badge for newly added images
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'NEW',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(String imageUrl) {
    if (imageUrl.startsWith('temp://')) {
      // New image (XFile)
      final imageIndex =
          _tempPhotoUrls.indexOf(imageUrl) - _existingPhotoUrls.length;
      if (imageIndex >= 0 && imageIndex < _newImages.length) {
        return FutureBuilder<Uint8List>(
          future: _newImages[imageIndex].readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Image.memory(
                snapshot.data!,
                fit: BoxFit.cover,
                width: 100,
                height: 100,
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        );
      }
    } else if (imageUrl.startsWith('data:image')) {
      // Base64 image (Web)
      try {
        final bytes = base64Decode(imageUrl.split(',')[1]);
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (e) {
        return _buildErrorImage();
      }
    } else if (imageUrl.startsWith('http')) {
      // Network image
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
      );
    } else {
      // File path (Mobile)
      return Image.file(
        File(imageUrl),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
      );
    }

    return _buildErrorImage();
  }

  Widget _buildErrorImage() {
    return const Icon(Icons.broken_image, color: Colors.grey, size: 40);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(translate(context, 'edit_report')),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.secondary,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSubmitting ? null : _submitEdit,
            tooltip: translate(context, 'save_changes'),
          ),
        ],
      ),
      body: Consumer<SiteProvider>(
        builder: (context, siteProvider, child) {
          if (siteProvider.currentSite == null) {
            return Center(child: Text(translate(context, 'no_site_selected')));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Description Field
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: translate(context, 'description'),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return translate(context, 'please_enter_description');
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Zone Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedZone.isEmpty ? null : _selectedZone,
                    decoration: InputDecoration(
                      labelText: translate(context, 'select_zone'),
                      border: const OutlineInputBorder(),
                    ),
                    items: siteProvider.currentSite!.zones.map((zone) {
                      return DropdownMenuItem(
                        value: zone.id,
                        child: Text(zone.getName(context)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedZone = value ?? '';
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return translate(context, 'please_select_zone');
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Report Type
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            translate(context, 'report_type'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<ReportType>(
                                  title: Text(translate(context, 'work')),
                                  value: ReportType.work,
                                  groupValue: _selectedType,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedType = value!;
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<ReportType>(
                                  title: Text(translate(context, 'hazard')),
                                  value: ReportType.hazard,
                                  groupValue: _selectedType,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedType = value!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // IMAGE MANAGEMENT SECTION
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            translate(context, 'photos'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Image Statistics
                          Text(
                            '${_existingPhotoUrls.length} existing photos • '
                            '${_newImages.length} new photos • '
                            '${_removedPhotoUrls.length} removed',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Add Image Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _pickImageFromCamera,
                                  icon: const Icon(Icons.camera_alt),
                                  label: Text(translate(context, 'take_photo')),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _pickImageFromGallery,
                                  icon: const Icon(Icons.photo_library),
                                  label:
                                      Text(translate(context, 'from_gallery')),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Image Preview Gallery
                          if (_tempPhotoUrls.isNotEmpty) ...[
                            Text(
                              'Current images (tap × to remove):',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 110,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _tempPhotoUrls.length,
                                itemBuilder: (context, index) {
                                  final isExisting =
                                      index < _existingPhotoUrls.length;
                                  return _buildImagePreview(
                                      _tempPhotoUrls[index], index, isExisting);
                                },
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  translate(context, 'no_images_added'),
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Map Location Section (Optional - reuse from creation page)
                  // if (widget.report.mapX != null || _mapX != null) ...[
                  //   Card(
                  //     child: Padding(
                  //       padding: const EdgeInsets.all(16),
                  //       child: Column(
                  //         crossAxisAlignment: CrossAxisAlignment.start,
                  //         children: [
                  //           Text(
                  //             translate(context, 'map_location'),
                  //             style: const TextStyle(
                  //               fontSize: 16,
                  //               fontWeight: FontWeight.bold,
                  //             ),
                  //           ),
                  //           const SizedBox(height: 8),
                  //           Text(
                  //             '${translate(context, 'current_location')}: '
                  //             '${((_mapX ?? widget.report.mapX ?? 0) * 100).toStringAsFixed(1)}%, '
                  //             '${((_mapY ?? widget.report.mapY ?? 0) * 100).toStringAsFixed(1)}%',
                  //             style: TextStyle(color: Colors.grey[600]),
                  //           ),
                  //           const SizedBox(height: 12),
                  //           // You can add map widget here to allow location changes
                  //         ],
                  //       ),
                  //     ),
                  //   ),
                  //   const SizedBox(height: 16),
                  // ],

                  // Save Button
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitEdit,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(translate(context, 'save_changes')),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
