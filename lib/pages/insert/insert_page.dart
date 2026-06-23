import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;
import 'package:flutter_web_dashboard/config.dart';
import 'package:flutter_web_dashboard/constants/style.dart';

class InsertPage extends StatefulWidget {
  const InsertPage({Key? key}) : super(key: key);

  @override
  _InsertPageState createState() => _InsertPageState();
}

class _InsertPageState extends State<InsertPage> {
  String? selectedOption;
  String? selectedtype;
  TextEditingController catNameController = TextEditingController();
  TextEditingController topicNameController = TextEditingController();
  html.File? selectedImage;
  Uint8List? imageBytes;
  PlatformFile? selectedFile;
  bool isUploading = false;
  bool isTopicSaving = false;
  Map<String, dynamic>? fbSummary;

  static const _uploadTypes = [
    ('User', Icons.people_rounded),
    ('Category', Icons.category_rounded),
    ('Topic', Icons.topic_rounded),
    ('Hotline Numbers', Icons.phone_rounded),
    ('Apps', Icons.apps_rounded),
    ('FB Page', Icons.facebook_rounded),
  ];

  Future<void> pickExcelFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'xlsm'],
      withData: true,
    );
    setState(() {
      selectedFile = (result != null && result.files.isNotEmpty)
          ? result.files.first
          : null;
    });
  }

  Future<void> uploadExcelFile() async {
    if (selectedFile == null) {
      _snack("Please select an Excel file to upload.");
      return;
    }
    setState(() => isUploading = true);
    final uri = Uri.parse("$host/api/upload-users/");
    var request = http.MultipartRequest("POST", uri);
    request.files.add(http.MultipartFile.fromBytes(
        "file", selectedFile!.bytes!,
        filename: selectedFile!.name));
    try {
      var response = await request.send();
      if (response.statusCode == 201) {
        _snack("Data uploaded successfully!", success: true);
      } else {
        var body = await response.stream.bytesToString();
        _snack("Upload failed: $body");
      }
    } catch (e) {
      _snack("Error: $e");
    } finally {
      setState(() => isUploading = false);
    }
  }

  Future<void> uploadHotlineNumbers() async {
    if (selectedFile == null) {
      _snack("Please select an Excel file to upload.");
      return;
    }
    setState(() => isUploading = true);
    final uri = Uri.parse("$host/api/upload-hotline-numbers/");
    var request = http.MultipartRequest("POST", uri);
    request.files.add(http.MultipartFile.fromBytes(
        "file", selectedFile!.bytes!,
        filename: selectedFile!.name));
    try {
      var response = await request.send();
      if (response.statusCode == 201) {
        _snack("Hotline numbers uploaded successfully!", success: true);
      } else {
        var body = await response.stream.bytesToString();
        _snack("Upload failed: $body");
      }
    } catch (e) {
      _snack("Error: $e");
    } finally {
      setState(() => isUploading = false);
    }
  }

  Future<void> uploadapps() async {
    if (selectedFile == null) {
      _snack("Please select an Excel file to upload.");
      return;
    }
    setState(() => isUploading = true);
    final uri = Uri.parse("$host/api/upload-apps/");
    var request = http.MultipartRequest("POST", uri);
    request.files.add(http.MultipartFile.fromBytes(
        "file", selectedFile!.bytes!,
        filename: selectedFile!.name));
    try {
      var response = await request.send();
      if (response.statusCode == 201) {
        _snack("Apps uploaded successfully!", success: true);
      } else {
        var body = await response.stream.bytesToString();
        _snack("Upload failed: $body");
      }
    } catch (e) {
      _snack("Error: $e");
    } finally {
      setState(() => isUploading = false);
    }
  }

  Future<void> pickImage() async {
    html.FileUploadInputElement input = html.FileUploadInputElement();
    input.accept = 'image/*';
    input.click();
    input.onChange.listen((e) async {
      final files = input.files;
      if (files!.isEmpty) return;
      setState(() => selectedImage = files[0]);
      final reader = html.FileReader();
      reader.readAsArrayBuffer(selectedImage!);
      reader.onLoadEnd.listen((e) {
        setState(() => imageBytes = reader.result as Uint8List);
      });
    });
  }

  Future<void> submitData() async {
    if (catNameController.text.isEmpty || selectedImage == null) {
      _snack("All fields are required!");
      return;
    }
    bool isService = selectedtype == "service";
    bool isShop = selectedtype == "shop";
    final uri = Uri.parse('$host/api/insert-cat/');
    var request = http.MultipartRequest('POST', uri)
      ..fields['cat_name'] = catNameController.text
      ..fields['yes_service'] = isService.toString()
      ..fields['yes_shop'] = isShop.toString()
      ..files.add(await http.MultipartFile.fromBytes(
        'cat_logo', imageBytes!,
        filename: selectedImage!.name,
      ));
    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        _snack("Category created successfully!", success: true);
        catNameController.clear();
        setState(() {
          selectedImage = null;
          imageBytes = null;
          selectedtype = null;
        });
      } else {
        _snack("Failed to create category!");
      }
    } catch (e) {
      _snack("Error occurred while inserting data!");
    }
  }

  Future<void> submitTopic() async {
    final name = topicNameController.text.trim();
    if (name.isEmpty) {
      _snack("Topic name is required.");
      return;
    }
    setState(() => isTopicSaving = true);
    try {
      final response = await http.post(
        Uri.parse("$host/api/insert-topic/"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"des_cat_name": name}),
      );
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        _snack("Topic '${data['des_cat_name']}' created (ID: ${data['des_cat_id']})", success: true);
        topicNameController.clear();
      } else {
        final data = json.decode(response.body);
        _snack(data['error'] ?? "Failed to create topic.");
      }
    } catch (e) {
      _snack("Error: $e");
    } finally {
      setState(() => isTopicSaving = false);
    }
  }

  Future<void> uploadFbPages() async {
    if (selectedFile == null) {
      _snack("Please select an Excel file to upload.");
      return;
    }
    setState(() => isUploading = true);
    final uri = Uri.parse("$host/api/upload-fb/");
    var request = http.MultipartRequest("POST", uri);
    request.files.add(http.MultipartFile.fromBytes(
        "file", selectedFile!.bytes!,
        filename: selectedFile!.name));
    try {
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      if (response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(responseBody);
        setState(() => fbSummary = jsonResponse["summary"]);
        _snack("FB Pages uploaded successfully!", success: true);
      } else {
        _snack("Upload failed: $responseBody");
      }
    } catch (e) {
      _snack("Error: $e");
    } finally {
      setState(() => isUploading = false);
    }
  }

  @override
  void dispose() {
    catNameController.dispose();
    topicNameController.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? successColor : errorColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page header
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 20),
            child: Row(
              children: [
                const Icon(Icons.upload_file_rounded,
                    size: 22, color: accentColor),
                const SizedBox(width: 10),
                const Text('Data Upload',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textPrimary)),
              ],
            ),
          ),

          // Upload type selector
          _UploadTypeGrid(
            selected: selectedOption,
            types: _uploadTypes,
            onSelect: (v) => setState(() {
              selectedOption = v;
              selectedFile = null;
              fbSummary = null;
            }),
          ),

          const SizedBox(height: 20),

          // Form area
          if (selectedOption != null)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: KeyedSubtree(
                key: ValueKey(selectedOption),
                child: _formForOption(selectedOption!),
              ),
            ),
        ],
      ),
    );
  }

  Widget _formForOption(String option) {
    switch (option) {
      case 'User':
        return _ExcelUploadCard(
          title: 'Upload User Data',
          subtitle: 'Upload an Excel sheet with user records.',
          selectedFile: selectedFile,
          isUploading: isUploading,
          onPick: pickExcelFile,
          onUpload: uploadExcelFile,
          uploadLabel: 'Upload Users',
        );
      case 'Hotline Numbers':
        return _ExcelUploadCard(
          title: 'Upload Hotline Numbers',
          subtitle: 'Upload an Excel sheet with hotline number records.',
          selectedFile: selectedFile,
          isUploading: isUploading,
          onPick: pickExcelFile,
          onUpload: uploadHotlineNumbers,
          uploadLabel: 'Upload Hotline Numbers',
          instructions: [
            'Columns required: name, phone, category, photo',
            'Rows with missing name, phone, or category will be skipped',
            'All cell values must be lowercase',
            'Sheet name must be "data"',
          ],
        );
      case 'Apps':
        return _ExcelUploadCard(
          title: 'Upload App Links',
          subtitle: 'Upload an Excel sheet with app link records.',
          selectedFile: selectedFile,
          isUploading: isUploading,
          onPick: pickExcelFile,
          onUpload: uploadapps,
          uploadLabel: 'Upload Apps',
          instructions: [
            'Columns required: name, web, address, category, photo',
            'Rows with missing name, web, or category will be skipped',
            'All cell values must be lowercase',
            'Sheet name must be "apps"',
          ],
        );
      case 'FB Page':
        return _FbUploadCard(
          selectedFile: selectedFile,
          isUploading: isUploading,
          fbSummary: fbSummary,
          onPick: pickExcelFile,
          onUpload: uploadFbPages,
        );
      case 'Category':
        return _buildCategoryCard();
      case 'Topic':
        return _buildTopicCard();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTopicCard() {
    return _FormCard(
      title: 'Create New Topic',
      icon: Icons.topic_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add a new topic to the des_cat table. Status is set to active (1) automatically.',
            style: TextStyle(fontSize: 13, color: textSecondary),
          ),
          const SizedBox(height: 20),

          const Text('Topic Name',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: topicNameController,
            style: const TextStyle(fontSize: 14, color: textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter topic name',
              hintStyle: const TextStyle(color: textMuted, fontSize: 14),
              prefixIcon: const Icon(Icons.topic_outlined,
                  size: 18, color: textMuted),
              filled: true,
              fillColor: background,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: borderColor)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: borderColor)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: accentColor, width: 1.5)),
            ),
          ),
          const SizedBox(height: 16),

          // Status info row (read-only)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: successColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: successColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: successColor, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                const Text('Status will be set to Active (1)',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: successColor)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isTopicSaving ? null : submitTopic,
              icon: isTopicSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.add_rounded,
                      size: 18, color: Colors.white),
              label: Text(
                isTopicSaving ? 'Creating...' : 'Create Topic',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                disabledBackgroundColor: accentColor.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard() {
    return _FormCard(
      title: 'Create New Category',
      icon: Icons.category_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name field
          const Text('Category Name',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: catNameController,
            style: const TextStyle(fontSize: 14, color: textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter category name',
              hintStyle: const TextStyle(color: textMuted, fontSize: 14),
              filled: true,
              fillColor: background,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: borderColor)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: borderColor)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: accentColor, width: 1.5)),
            ),
          ),
          const SizedBox(height: 20),

          // Type selector
          const Text('Category Type',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: ['service', 'shop'].map((type) {
              final isSelected = selectedtype == type;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () => setState(() => selectedtype = type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? accentColor : background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: isSelected ? accentColor : borderColor),
                    ),
                    child: Text(
                      type[0].toUpperCase() + type.substring(1),
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : textSecondary),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Image picker
          const Text('Category Logo',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: [
              // Image preview
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                clipBehavior: Clip.antiAlias,
                child: imageBytes != null
                    ? Image.memory(imageBytes!,
                        width: 80, height: 80, fit: BoxFit.cover)
                    : const Center(
                        child: Icon(Icons.image_outlined,
                            color: textMuted, size: 32)),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: pickImage,
                icon: const Icon(Icons.upload_rounded,
                    size: 16, color: accentColor),
                label: const Text('Choose Image',
                    style: TextStyle(color: accentColor, fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: accentColor),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Submit
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: submitData,
              icon: const Icon(Icons.add_rounded,
                  size: 18, color: Colors.white),
              label: const Text('Create Category',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Upload type selector grid ──────────────────────────────────────────────

class _UploadTypeGrid extends StatelessWidget {
  final String? selected;
  final List<(String, IconData)> types;
  final ValueChanged<String> onSelect;

  const _UploadTypeGrid(
      {required this.selected,
      required this.types,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: types.map((t) {
        final isSelected = selected == t.$1;
        return GestureDetector(
          onTap: () => onSelect(t.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? accentColor : surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: isSelected ? accentColor : borderColor, width: 1.5),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: accentColor.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(t.$2,
                    size: 18,
                    color: isSelected ? Colors.white : textSecondary),
                const SizedBox(width: 8),
                Text(t.$1,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color:
                            isSelected ? Colors.white : textSecondary)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Reusable Excel upload card ─────────────────────────────────────────────

class _ExcelUploadCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final PlatformFile? selectedFile;
  final bool isUploading;
  final VoidCallback onPick;
  final VoidCallback onUpload;
  final String uploadLabel;
  final List<String>? instructions;

  const _ExcelUploadCard({
    required this.title,
    required this.subtitle,
    required this.selectedFile,
    required this.isUploading,
    required this.onPick,
    required this.onUpload,
    required this.uploadLabel,
    this.instructions,
  });

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      title: title,
      icon: Icons.table_chart_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle,
              style: const TextStyle(fontSize: 13, color: textSecondary)),

          // Instructions box
          if (instructions != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: warningColor.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.info_outline_rounded,
                        size: 14, color: warningColor),
                    const SizedBox(width: 6),
                    const Text('Format Requirements',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF92400E))),
                  ]),
                  const SizedBox(height: 8),
                  ...instructions!.map((line) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ',
                                style: TextStyle(
                                    color: Color(0xFF92400E),
                                    fontSize: 12)),
                            Expanded(
                              child: Text(line,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF92400E))),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // File picker area
          GestureDetector(
            onTap: onPick,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: selectedFile != null ? successColor : borderColor,
                    width: 1.5,
                    style: BorderStyle.solid),
              ),
              child: Column(
                children: [
                  Icon(
                    selectedFile != null
                        ? Icons.check_circle_rounded
                        : Icons.upload_file_rounded,
                    size: 32,
                    color:
                        selectedFile != null ? successColor : textMuted,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selectedFile != null
                        ? selectedFile!.name
                        : 'Click to select Excel file (.xlsx / .xls)',
                    style: TextStyle(
                        fontSize: 13,
                        color: selectedFile != null
                            ? successColor
                            : textSecondary,
                        fontWeight: selectedFile != null
                            ? FontWeight.w600
                            : FontWeight.normal),
                  ),
                  if (selectedFile == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text('Supports .xlsx, .xls, .xlsm',
                          style:
                              TextStyle(fontSize: 11, color: textMuted)),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Upload button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isUploading ? null : onUpload,
              icon: isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.cloud_upload_rounded,
                      size: 18, color: Colors.white),
              label: Text(
                isUploading ? 'Uploading...' : uploadLabel,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                disabledBackgroundColor:
                    accentColor.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── FB Page card (has summary) ─────────────────────────────────────────────

class _FbUploadCard extends StatelessWidget {
  final PlatformFile? selectedFile;
  final bool isUploading;
  final Map<String, dynamic>? fbSummary;
  final VoidCallback onPick;
  final VoidCallback onUpload;

  const _FbUploadCard({
    required this.selectedFile,
    required this.isUploading,
    required this.fbSummary,
    required this.onPick,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ExcelUploadCard(
          title: 'Upload FB Page Data',
          subtitle: 'Upload an Excel sheet with Facebook page records.',
          selectedFile: selectedFile,
          isUploading: isUploading,
          onPick: onPick,
          onUpload: onUpload,
          uploadLabel: 'Upload FB Pages',
          instructions: [
            'Columns required: name, web, address, phone, category, photo (optional)',
            'Rows with missing name, web, phone, or category will be skipped',
            'Sheet name must be "fb_page"',
          ],
        ),
        if (fbSummary != null) ...[
          const SizedBox(height: 16),
          _FormCard(
            title: 'Upload Summary',
            icon: Icons.analytics_rounded,
            child: Row(
              children: [
                _SummaryTile(
                    label: 'Total Rows',
                    value: '${fbSummary!['total_rows']}',
                    color: textPrimary),
                _SummaryTile(
                    label: 'Added',
                    value: '${fbSummary!['added_count']}',
                    color: successColor),
                _SummaryTile(
                    label: 'Skipped',
                    value: '${fbSummary!['skipped_count']}',
                    color: warningColor),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryTile(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 12, color: textSecondary)),
        ],
      ),
    );
  }
}

// ── Shared card wrapper ────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _FormCard(
      {required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 18, color: accentColor),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textPrimary)),
          ]),
          const SizedBox(height: 4),
          const Divider(color: borderColor, height: 20),
          child,
        ],
      ),
    );
  }
}
