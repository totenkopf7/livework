// UPDATED: lib/report_creation_page.dart
import 'package:flutter/material.dart';
import 'package:livework_view/widgets/colors.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'providers/report_provider.dart';
import 'providers/site_provider.dart';
import 'providers/auth_provider.dart' as livework_auth;
import 'data/models/report_model.dart';
import 'widgets/custom_map_widget.dart';
import 'helpers/localization_helper.dart'; // ADDED

class ReportCreationPage extends StatefulWidget {
  const ReportCreationPage({Key? key}) : super(key: key);

  @override
  State<ReportCreationPage> createState() => _ReportCreationPageState();
}

class _ReportCreationPageState extends State<ReportCreationPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();

  ReportType _selectedType = ReportType.work;
  String _selectedZone = '';
  List<XFile> _selectedImages = [];
  bool _isSubmitting = false;
  double? _mapX;
  double? _mapY;
  List<String> _uploadErrors = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadZones();
    });
  }

  void _loadZones() {
    final siteProvider = Provider.of<SiteProvider>(context, listen: false);
    if (siteProvider.currentSite != null &&
        siteProvider.currentSite!.zones.isNotEmpty) {
      setState(() {
        _selectedZone = siteProvider.currentSite!.zones.first.id;
      });
    }
  }

  Future<Uint8List> _compressImage(XFile imageFile,
      {int maxSizeKB = 200}) async {
    try {
      final bytes = await imageFile.readAsBytes();

      if (bytes.lengthInBytes <= maxSizeKB * 1024) {
        return bytes;
      }

      final image = img.decodeImage(bytes);
      if (image == null) return bytes;

      int quality = 70;
      Uint8List compressedBytes = bytes;

      while (compressedBytes.lengthInBytes > maxSizeKB * 1024 && quality > 10) {
        quality -= 10;
        compressedBytes =
            Uint8List.fromList(img.encodeJpg(image, quality: quality));
      }

      if (compressedBytes.lengthInBytes > maxSizeKB * 1024) {
        double scaleFactor = 0.9;
        img.Image resizedImage = image;

        while (compressedBytes.lengthInBytes > maxSizeKB * 1024 &&
            scaleFactor > 0.3) {
          int newWidth = (resizedImage.width * scaleFactor).round();
          int newHeight = (resizedImage.height * scaleFactor).round();

          resizedImage =
              img.copyResize(resizedImage, width: newWidth, height: newHeight);
          compressedBytes =
              Uint8List.fromList(img.encodeJpg(resizedImage, quality: quality));

          scaleFactor -= 0.1;
        }
      }

      return compressedBytes;
    } catch (e) {
      print('Image compression error: $e');
      return await imageFile.readAsBytes();
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      print('Camera error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking photo: $e')),
      );
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      print('Gallery error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _onMapLocationSelected(double x, double y) {
    setState(() {
      _mapX = x;
      _mapY = y;
    });
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedZone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(translate(
                context, 'please_select_zone'))), // UPDATED: Use translation
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _uploadErrors.clear();
    });

    try {
      final reportProvider =
          Provider.of<ReportProvider>(context, listen: false);
      final siteProvider = Provider.of<SiteProvider>(context, listen: false);

      if (siteProvider.currentSite == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(translate(
                  context, 'no_site_selected'))), // UPDATED: Use translation
        );
        return;
      }

      List<String> photoUrls = [];
      int imageIndex = 0;

      for (XFile image in _selectedImages) {
        try {
          imageIndex++;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Processing image $imageIndex/${_selectedImages.length}'),
              duration: const Duration(seconds: 1),
            ),
          );

          if (kIsWeb) {
            final compressedBytes = await _compressImage(image, maxSizeKB: 200);
            final base64String = base64Encode(compressedBytes);
            photoUrls.add('data:image/jpeg;base64,$base64String');
          } else {
            final compressedBytes = await _compressImage(image, maxSizeKB: 200);

            final tempDir = Directory.systemTemp;
            final tempFile = File(
                '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_$imageIndex.jpg');
            await tempFile.writeAsBytes(compressedBytes);

            photoUrls.add(tempFile.path);
          }
        } catch (e) {
          print('Error processing image $imageIndex: $e');
          _uploadErrors.add('Image $imageIndex: $e');
        }
      }

      if (photoUrls.isEmpty && _selectedImages.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to process all images. Report not created.')),
        );
        return;
      }

      await reportProvider.createReport(
        siteId: siteProvider.currentSite!.id,
        zone: _selectedZone,
        type: _selectedType,
        description: _descriptionController.text,
        photoUrls: photoUrls,
        latitude: null,
        longitude: null,
        mapX: _mapX,
        mapY: _mapY,
      );

      if (_uploadErrors.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(translate(
                  context, 'report_created'))), // UPDATED: Use translation
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Report created with ${_uploadErrors.length} image errors'),
            action: SnackBarAction(
              label: 'Details',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(translate(context,
                        'image_upload_errors')), // UPDATED: Use translation
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _uploadErrors
                            .map((error) => Text('• $error'))
                            .toList(),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(translate(
                            context, 'ok')), // UPDATED: Use translation
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }

      _descriptionController.clear();
      setState(() {
        _selectedImages.clear();
        _mapX = null;
        _mapY = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating report: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider =
        Provider.of<livework_auth.LiveWorkAuthProvider>(context);

    if (!authProvider.isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
              translate(context, 'create_report')), // UPDATED: Use translation
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.secondary,
        ),
        body: Center(
          child: Text(
            translate(context,
                'no_permission_create_reports'), // UPDATED: Use translation
            style: TextStyle(fontSize: 16, color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
            translate(context, 'create_report')), // UPDATED: Use translation
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.secondary,
      ),
      body: Consumer<SiteProvider>(
        builder: (context, siteProvider, child) {
          if (siteProvider.currentSite == null) {
            return Center(
              child: Text(
                translate(
                    context, 'no_site_selected'), // UPDATED: Use translation
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            translate(context,
                                'report_type'), // UPDATED: Use translation
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<ReportType>(
                                  title: Text(translate(context,
                                      'work')), // UPDATED: Use translation
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
                                  title: Text(translate(context,
                                      'hazard')), // UPDATED: Use translation
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
                  SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            translate(context,
                                'task_zone'), // UPDATED: Use translation
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedZone.isEmpty ? null : _selectedZone,
                            decoration: InputDecoration(
                              labelText: translate(context,
                                  'select_zone'), // UPDATED: Use translation
                              border: OutlineInputBorder(),
                            ),
                            items: siteProvider.currentSite!.zones.map((zone) {
                              return DropdownMenuItem(
                                value: zone.id,
                                child: Text(zone
                                    .getName(context)), // Use localized name
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedZone = value ?? '';
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return translate(context,
                                    'please_select_zone'); // UPDATED: Use translation
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            translate(context,
                                'description'), // UPDATED: Use translation
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: translate(context,
                                  'describe_work_hazard'), // UPDATED: Use translation
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return translate(context,
                                    'please_enter_description'); // UPDATED: Use translation
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            translate(
                                context, 'photos'), // UPDATED: Use translation
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            translate(context,
                                'upload_photos'), // UPDATED: Use translation
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _pickImage,
                                  icon: Icon(Icons.camera_alt),
                                  label: Text(translate(context,
                                      'camera')), // UPDATED: Use translation
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _pickImageFromGallery,
                                  icon: Icon(Icons.photo_library),
                                  label: Text(translate(context,
                                      'gallery')), // UPDATED: Use translation
                                ),
                              ),
                            ],
                          ),
                          if (_selectedImages.isNotEmpty) ...[
                            SizedBox(height: 12),
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _selectedImages.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            color: Colors.grey[300],
                                          ),
                                          child: FutureBuilder<Uint8List>(
                                            future: _selectedImages[index]
                                                .readAsBytes(),
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData) {
                                                return ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: Image.memory(
                                                    snapshot.data!,
                                                    fit: BoxFit.cover,
                                                    width: 100,
                                                    height: 100,
                                                  ),
                                                );
                                              } else {
                                                return Icon(
                                                  Icons.image,
                                                  color: Colors.grey,
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _selectedImages.removeAt(index);
                                              });
                                            },
                                            child: Container(
                                              padding: EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            translate(context,
                                'select_location_map'), // UPDATED: Use translation
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            translate(context,
                                'tap_map_location'), // UPDATED: Use translation
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 12),
                          CustomMapWidget(
                            onLocationSelected: _onMapLocationSelected,
                            markers: _mapX != null && _mapY != null
                                ? [
                                    MapMarker(
                                      x: _mapX!,
                                      y: _mapY!,
                                      color: _selectedType == ReportType.work
                                          ? Colors.blue
                                          : Colors.red,
                                      icon: _selectedType == ReportType.work
                                          ? Icons.build
                                          : Icons.warning,
                                      label: translate(context,
                                          'selected_location'), // UPDATED: Use translation
                                    ),
                                  ]
                                : [],
                          ),
                          if (_mapX != null && _mapY != null) ...[
                            SizedBox(height: 12),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: Colors.green.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green.shade600,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${translate(context, 'location_selected')}: ${(_mapX! * 100).toStringAsFixed(1)}%, ${(_mapY! * 100).toStringAsFixed(1)}%', // UPDATED: Use translation
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSubmitting
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(translate(context,
                                  'creating_report')), // UPDATED: Use translation
                            ],
                          )
                        : Text(translate(context,
                            'submit_report')), // UPDATED: Use translation
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}
