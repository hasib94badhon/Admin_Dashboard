import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;
import 'package:flutter_web_dashboard/config.dart';
import 'package:flutter_web_dashboard/constants/style.dart';
import 'package:flutter_web_dashboard/service_api/auth_headers.dart';

// ── Flask admin helpers ───────────────────────────────────────────────────────

Map<String, String> get _adminHeaders => {
      'Content-Type': 'application/json',
      'X-Admin-Key': flaskAdminKey,
    };

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
    ('Sub Category', Icons.subdirectory_arrow_right_rounded),
    ('Hotline Numbers', Icons.phone_rounded),
    ('Apps', Icons.apps_rounded),
    ('FB Page', Icons.facebook_rounded),
    ('FB Page (Single)', Icons.add_box_rounded),
    ('YouTube Channel', Icons.smart_display_rounded),
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
    var request = http.MultipartRequest("POST", uri)
      ..headers.addAll(authHeadersMultipart());
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
    var request = http.MultipartRequest("POST", uri)
      ..headers.addAll(authHeadersMultipart());
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
    var request = http.MultipartRequest("POST", uri)
      ..headers.addAll(authHeadersMultipart());
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
      ..headers.addAll(authHeadersMultipart())
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
        headers: authHeaders(),
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
    var request = http.MultipartRequest("POST", uri)
      ..headers.addAll(authHeadersMultipart());
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
      case 'FB Page (Single)':
        return const _FbSingleManager();
      case 'YouTube Channel':
        return const _YtChannelManager();
      case 'Category':
        return _buildCategoryCard();
      case 'Topic':
        return _buildTopicCard();
      case 'Sub Category':
        return const _SubCatManager();
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

// ── Sub-Category Manager ───────────────────────────────────────────────────

class _SubCatManager extends StatefulWidget {
  const _SubCatManager();

  @override
  State<_SubCatManager> createState() => _SubCatManagerState();
}

// The backend still stores name_bn/name_en as two columns (create/update
// always write the same value into both — see _create()), so either one
// may be the populated one for older rows. Prefer name_bn, fall back to
// name_en, so the panel only ever shows a single name.
String _subCatName(Map<String, dynamic> s) {
  final bn = (s['name_bn'] as String?) ?? '';
  if (bn.isNotEmpty) return bn;
  return (s['name_en'] as String?) ?? '';
}

class _SubCatManagerState extends State<_SubCatManager> {
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _subCats = [];
  int? _filterCatId;
  bool _loadingCats = true;
  bool _loadingSubCats = false;
  bool _isSaving = false;

  // Add form
  int? _formCatId;
  final _nameCtrl = TextEditingController();
  final _emojiCtrl = TextEditingController();
  final _sortCtrl = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emojiCtrl.dispose();
    _sortCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    setState(() => _loadingCats = true);
    try {
      final res = await http.get(Uri.parse('$host/api/des-categories/'), headers: authHeaders());
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() => _categories = List<Map<String, dynamic>>.from(data['categories']));
      }
    } catch (_) {}
    setState(() => _loadingCats = false);
  }

  Future<void> _fetchSubCats(int catId) async {
    setState(() {
      _loadingSubCats = true;
      _filterCatId = catId;
    });
    try {
      final res = await http.get(
          Uri.parse('$host/api/des-sub-categories/?des_cat_id=$catId'),
          headers: authHeaders());
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() =>
            _subCats = List<Map<String, dynamic>>.from(data['sub_categories']));
      }
    } catch (_) {}
    setState(() => _loadingSubCats = false);
  }

  Future<void> _create() async {
    if (_formCatId == null || _nameCtrl.text.trim().isEmpty) {
      _snack('Category and name are required.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      // Backend still stores name_bn/name_en as two columns, but the app
      // only ever displays one — so both are populated with the same
      // admin-entered value rather than asking for two languages.
      final name = _nameCtrl.text.trim();
      final res = await http.post(
        Uri.parse('$host/api/des-sub-categories/create/'),
        headers: authHeaders(),
        body: json.encode({
          'des_cat_id': _formCatId,
          'name_bn': name,
          'name_en': name,
          'emoji': _emojiCtrl.text.trim(),
          'sort_order': int.tryParse(_sortCtrl.text) ?? 0,
        }),
      );
      final data = json.decode(res.body);
      if (res.statusCode == 201) {
        _snack('Sub-category created!', success: true);
        _nameCtrl.clear();
        _emojiCtrl.clear();
        _sortCtrl.text = '0';
        if (_filterCatId == _formCatId) _fetchSubCats(_formCatId!);
      } else {
        _snack(data['error'] ?? 'Failed to create.');
      }
    } catch (e) {
      _snack('Error: $e');
    }
    setState(() => _isSaving = false);
  }

  Future<void> _delete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Sub-Category'),
        content: const Text('Are you sure you want to delete this sub-category?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Delete', style: TextStyle(color: errorColor)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final res = await http.delete(Uri.parse('$host/api/des-sub-categories/$id/delete/'),
          headers: authHeaders());
      if (res.statusCode == 200) {
        _snack('Deleted.', success: true);
        if (_filterCatId != null) _fetchSubCats(_filterCatId!);
      } else {
        _snack('Delete failed.');
      }
    } catch (e) {
      _snack('Error: $e');
    }
  }

  Future<void> _showEditDialog(Map<String, dynamic> sub) async {
    final nameCtrl = TextEditingController(text: _subCatName(sub));
    final emCtrl = TextEditingController(text: sub['emoji'] ?? '');
    final soCtrl = TextEditingController(text: '${sub['sort_order'] ?? 0}');
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDlg) {
        return AlertDialog(
          title: const Text('Edit Sub-Category'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dlgField(nameCtrl, 'Name *'),
                const SizedBox(height: 12),
                _dlgField(emCtrl, 'Emoji'),
                const SizedBox(height: 12),
                _dlgField(soCtrl, 'Sort Order', keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      setDlg(() => saving = true);
                      try {
                        // Same value goes into both name_bn/name_en — see
                        // _create() for why.
                        final name = nameCtrl.text.trim();
                        final res = await http.put(
                          Uri.parse('$host/api/des-sub-categories/${sub['des_sub_cat_id']}/update/'),
                          headers: authHeaders(),
                          body: json.encode({
                            'name_bn': name,
                            'name_en': name,
                            'emoji': emCtrl.text.trim(),
                            'sort_order': int.tryParse(soCtrl.text) ?? 0,
                          }),
                        );
                        if (res.statusCode == 200) {
                          if (ctx.mounted) Navigator.pop(ctx);
                          _snack('Updated!', success: true);
                          if (_filterCatId != null) _fetchSubCats(_filterCatId!);
                        } else {
                          final d = json.decode(res.body);
                          _snack(d['error'] ?? 'Update failed.');
                        }
                      } catch (e) {
                        _snack('Error: $e');
                      }
                      setDlg(() => saving = false);
                    },
              style: ElevatedButton.styleFrom(backgroundColor: accentColor),
              child: saving
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      }),
    );
    nameCtrl.dispose();
    emCtrl.dispose();
    soCtrl.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchSuggestionsFor(int subCatId) async {
    try {
      final res = await http.get(
          Uri.parse('$host/api/des-cat-suggestions/?des_sub_cat_id=$subCatId'),
          headers: authHeaders());
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return List<Map<String, dynamic>>.from(data['suggestions']);
      }
    } catch (_) {}
    return [];
  }

  Future<void> _showSuggestionsDialog(Map<String, dynamic> sub) async {
    final subCatId = sub['des_sub_cat_id'] as int;
    final addCtrl = TextEditingController();
    List<Map<String, dynamic>> suggestions = await _fetchSuggestionsFor(subCatId);
    bool saving = false;
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDlg) {
        Future<void> reload() async {
          final fresh = await _fetchSuggestionsFor(subCatId);
          setDlg(() => suggestions = fresh);
        }

        Future<void> add() async {
          final text = addCtrl.text.trim();
          if (text.isEmpty) return;
          setDlg(() => saving = true);
          try {
            final res = await http.post(
              Uri.parse('$host/api/des-cat-suggestions/create/'),
              headers: authHeaders(),
              body: json.encode({
                'des_sub_cat_id': subCatId,
                'suggestion_text': text,
                'sort_order': suggestions.length,
              }),
            );
            if (res.statusCode == 201) {
              addCtrl.clear();
              await reload();
            } else {
              _snack('Failed to add suggestion.');
            }
          } catch (e) {
            _snack('Error: $e');
          }
          setDlg(() => saving = false);
        }

        Future<void> removeOne(int id) async {
          try {
            final res = await http.delete(
                Uri.parse('$host/api/des-cat-suggestions/$id/delete/'),
                headers: authHeaders());
            if (res.statusCode == 200) {
              await reload();
            } else {
              _snack('Delete failed.');
            }
          } catch (e) {
            _snack('Error: $e');
          }
        }

        return AlertDialog(
          title: Text('Suggestions — ${_subCatName(sub)}'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _dlgField(addCtrl, 'New suggestion text')),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: saving ? null : add,
                      style: ElevatedButton.styleFrom(backgroundColor: accentColor),
                      child: saving
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Add', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (suggestions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                        child: Text('No suggestions yet.',
                            style: TextStyle(color: textMuted))),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: suggestions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final s = suggestions[i];
                        return ListTile(
                          dense: true,
                          title: Text(s['suggestion_text'] ?? '',
                              style: const TextStyle(fontSize: 13)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 18, color: errorColor),
                            onPressed: () => removeOne(s['id'] as int),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        );
      }),
    );
    addCtrl.dispose();
  }

  Widget _dlgField(TextEditingController ctrl, String label,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
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
    return Column(
      children: [
        // ── Add new sub-category form ─────────────────────────────
        _FormCard(
          title: 'Add Sub-Category',
          icon: Icons.add_circle_outline_rounded,
          child: _loadingCats
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select a topic category, then enter sub-category details.',
                      style: TextStyle(fontSize: 13, color: textSecondary),
                    ),
                    const SizedBox(height: 20),

                    // Category dropdown
                    const Text('Topic Category *',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textSecondary)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _formCatId,
                      decoration: InputDecoration(
                        hintText: 'Select category',
                        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
                        filled: true,
                        fillColor: background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: accentColor, width: 1.5)),
                      ),
                      items: _categories
                          .map((c) => DropdownMenuItem<int>(
                                value: c['des_cat_id'] as int,
                                child: Text(
                                    '${c['des_cat_id']} · ${c['des_cat_name']}',
                                    style: const TextStyle(fontSize: 14, color: textPrimary)),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _formCatId = v),
                    ),
                    const SizedBox(height: 16),

                    // Name (Bengali or English — admin's choice, one field only)
                    const Text('Name *',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textSecondary)),
                    const SizedBox(height: 8),
                    _inputField(_nameCtrl, 'যেমন: সম্পত্তির বিজ্ঞাপন / Property Ads'),
                    const SizedBox(height: 16),

                    // Emoji + sort in a row
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Emoji',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textSecondary)),
                              const SizedBox(height: 8),
                              _inputField(_emojiCtrl, '🏠'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Sort',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textSecondary)),
                              const SizedBox(height: 8),
                              _inputField(_sortCtrl, '0', keyboardType: TextInputType.number),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _create,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                        label: Text(
                          _isSaving ? 'Saving...' : 'Add Sub-Category',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          disabledBackgroundColor: accentColor.withValues(alpha: 0.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
        ),

        const SizedBox(height: 20),

        // ── Sub-category list ─────────────────────────────────────
        _FormCard(
          title: 'Browse Sub-Categories',
          icon: Icons.list_alt_rounded,
          child: _loadingCats
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filter dropdown
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _filterCatId,
                            decoration: InputDecoration(
                              hintText: 'Select category to load sub-cats',
                              hintStyle: const TextStyle(color: textMuted, fontSize: 13),
                              filled: true,
                              fillColor: background,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: borderColor)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: borderColor)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: accentColor, width: 1.5)),
                            ),
                            items: _categories
                                .map((c) => DropdownMenuItem<int>(
                                      value: c['des_cat_id'] as int,
                                      child: Text('${c['des_cat_id']} · ${c['des_cat_name']}',
                                          style: const TextStyle(fontSize: 13, color: textPrimary)),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) _fetchSubCats(v);
                            },
                          ),
                        ),
                      ],
                    ),

                    if (_loadingSubCats) ...[
                      const SizedBox(height: 24),
                      const Center(child: CircularProgressIndicator()),
                    ] else if (_filterCatId != null && _subCats.isEmpty) ...[
                      const SizedBox(height: 24),
                      const Center(
                        child: Text('No sub-categories found for this category.',
                            style: TextStyle(fontSize: 13, color: textSecondary)),
                      ),
                    ] else if (_subCats.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      // Table header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            SizedBox(width: 40, child: Text('ID', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSecondary))),
                            Expanded(flex: 5, child: Text('Name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSecondary))),
                            SizedBox(width: 40, child: Text('Emoji', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSecondary))),
                            SizedBox(width: 40, child: Text('Sort', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSecondary))),
                            SizedBox(width: 108, child: Text('Actions', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSecondary))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      ..._subCats.asMap().entries.map((e) {
                        final i = e.key;
                        final s = e.value;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: i.isEven ? surface : background,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              SizedBox(width: 40, child: Text('${s['des_sub_cat_id']}', style: const TextStyle(fontSize: 12, color: textMuted))),
                              Expanded(flex: 5, child: Text(_subCatName(s), style: const TextStyle(fontSize: 13, color: textPrimary))),
                              SizedBox(width: 40, child: Text(s['emoji'] ?? '', style: const TextStyle(fontSize: 16))),
                              SizedBox(width: 40, child: Text('${s['sort_order']}', style: const TextStyle(fontSize: 12, color: textMuted))),
                              SizedBox(
                                width: 108,
                                child: Row(
                                  children: [
                                    InkWell(
                                      onTap: () => _showSuggestionsDialog(s),
                                      borderRadius: BorderRadius.circular(4),
                                      child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(Icons.auto_awesome_rounded, size: 16, color: accentColor),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    InkWell(
                                      onTap: () => _showEditDialog(s),
                                      borderRadius: BorderRadius.circular(4),
                                      child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(Icons.edit_rounded, size: 16, color: accentColor),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    InkWell(
                                      onTap: () => _delete(s['des_sub_cat_id'] as int),
                                      borderRadius: BorderRadius.circular(4),
                                      child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(Icons.delete_outline_rounded, size: 16, color: errorColor),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _inputField(TextEditingController ctrl, String hint,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        filled: true,
        fillColor: background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: borderColor)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: accentColor, width: 1.5)),
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

// ── FB Page single-insert manager ─────────────────────────────────────────

class _FbSingleManager extends StatefulWidget {
  const _FbSingleManager();
  @override
  State<_FbSingleManager> createState() => _FbSingleManagerState();
}

class _FbSingleManagerState extends State<_FbSingleManager> {
  final _name     = TextEditingController();
  final _cat      = TextEditingController();
  final _photo    = TextEditingController();
  final _link     = TextEditingController();
  final _phone    = TextEditingController();
  final _location = TextEditingController();

  bool _saving = false;
  bool _loadingList = false;
  List<Map<String, dynamic>> _pages = [];

  @override
  void initState() {
    super.initState();
    _fetchList();
  }

  @override
  void dispose() {
    for (final c in [_name, _cat, _photo, _link, _phone, _location]) c.dispose();
    super.dispose();
  }

  Future<void> _fetchList() async {
    setState(() => _loadingList = true);
    try {
      final res = await http.get(
        Uri.parse('$flaskApi/admin/fb_pages'),
        headers: _adminHeaders,
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() => _pages = List<Map<String, dynamic>>.from(data['fb_pages']));
      }
    } catch (_) {}
    setState(() => _loadingList = false);
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty || _cat.text.trim().isEmpty || _link.text.trim().isEmpty) {
      _snack('Name, category, and link are required.');
      return;
    }
    setState(() => _saving = true);
    try {
      final res = await http.post(
        Uri.parse('$flaskApi/admin/fb_page/add'),
        headers: _adminHeaders,
        body: json.encode({
          'name': _name.text.trim(),
          'cat': _cat.text.trim(),
          'photo': _photo.text.trim(),
          'link': _link.text.trim(),
          'phone': _phone.text.trim(),
          'location': _location.text.trim(),
        }),
      );
      if (res.statusCode == 201) {
        _snack('Facebook page added!', success: true);
        for (final c in [_name, _cat, _photo, _link, _phone, _location]) c.clear();
        _fetchList();
      } else {
        final d = json.decode(res.body);
        _snack(d['error'] ?? 'Failed to add page.');
      }
    } catch (e) {
      _snack('Error: $e');
    }
    setState(() => _saving = false);
  }

  Future<void> _delete(int pageId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Page'),
        content: const Text('Remove this Facebook page?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Delete', style: TextStyle(color: errorColor)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final res = await http.delete(
        Uri.parse('$flaskApi/admin/fb_page/$pageId'),
        headers: _adminHeaders,
      );
      if (res.statusCode == 200) {
        _snack('Deleted.', success: true);
        _fetchList();
      } else {
        _snack('Delete failed.');
      }
    } catch (e) {
      _snack('Error: $e');
    }
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
    return Column(children: [
      _FormCard(
        title: 'Add Facebook Page',
        icon: Icons.facebook_rounded,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Add an individual Facebook page to the directory.',
              style: TextStyle(fontSize: 13, color: textSecondary)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _field(_name, 'Page Name *')),
            const SizedBox(width: 12),
            Expanded(child: _field(_cat, 'Category *', hint: 'e.g. News, Entertainment')),
          ]),
          const SizedBox(height: 12),
          _field(_link, 'Facebook Page Link *', hint: 'https://facebook.com/pagename'),
          const SizedBox(height: 12),
          _field(_photo, 'Profile Photo URL', hint: 'https://...'),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _field(_phone, 'Phone (optional)')),
            const SizedBox(width: 12),
            Expanded(child: _field(_location, 'Location (optional)')),
          ]),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.add_rounded, size: 18, color: Colors.white),
              label: Text(_saving ? 'Adding...' : 'Add Facebook Page',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1877F2),
                disabledBackgroundColor: const Color(0xFF1877F2).withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 20),
      _FormCard(
        title: 'Existing Facebook Pages',
        icon: Icons.list_alt_rounded,
        child: _loadingList
            ? const Center(child: CircularProgressIndicator())
            : _pages.isEmpty
                ? const Text('No pages yet.', style: TextStyle(color: textSecondary, fontSize: 13))
                : Column(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(children: [
                        Expanded(flex: 3, child: Text('Name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSecondary))),
                        Expanded(flex: 2, child: Text('Category', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSecondary))),
                        SizedBox(width: 60, child: Text('Visits', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSecondary))),
                        SizedBox(width: 50, child: Text('', style: TextStyle(fontSize: 11))),
                      ]),
                    ),
                    const SizedBox(height: 4),
                    ..._pages.asMap().entries.map((e) {
                      final i = e.key;
                      final p = e.value;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: i.isEven ? surface : background,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(children: [
                          Expanded(flex: 3, child: Text(p['name'] ?? '', style: const TextStyle(fontSize: 13, color: textPrimary), overflow: TextOverflow.ellipsis)),
                          Expanded(flex: 2, child: Text(p['cat'] ?? '', style: const TextStyle(fontSize: 12, color: textSecondary), overflow: TextOverflow.ellipsis)),
                          SizedBox(width: 60, child: Text('${p['visit_count'] ?? 0}', style: const TextStyle(fontSize: 12, color: textMuted))),
                          SizedBox(
                            width: 50,
                            child: InkWell(
                              onTap: () => _delete(p['page_id'] as int),
                              borderRadius: BorderRadius.circular(4),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.delete_outline_rounded, size: 16, color: errorColor),
                              ),
                            ),
                          ),
                        ]),
                      );
                    }),
                  ]),
      ),
    ]);
  }

  Widget _field(TextEditingController ctrl, String label,
      {String? hint, TextInputType keyboardType = TextInputType.text}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textSecondary)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, color: textPrimary),
        decoration: InputDecoration(
          hintText: hint ?? label.replaceAll(' *', ''),
          hintStyle: const TextStyle(color: textMuted, fontSize: 13),
          filled: true,
          fillColor: background,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderColor)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderColor)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: accentColor, width: 1.5)),
        ),
      ),
    ]);
  }
}


// ── YouTube Channel manager ────────────────────────────────────────────────

class _YtChannelManager extends StatefulWidget {
  const _YtChannelManager();
  @override
  State<_YtChannelManager> createState() => _YtChannelManagerState();
}

class _YtChannelManagerState extends State<_YtChannelManager>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  // Single add
  final _name  = TextEditingController();
  final _cat   = TextEditingController();
  final _photo = TextEditingController();
  final _link  = TextEditingController();
  bool _saving = false;

  // Bulk add (JSON paste)
  final _bulkCtrl = TextEditingController();
  bool _bulkSaving = false;
  Map<String, dynamic>? _bulkResult;

  // List
  bool _loadingList = false;
  List<Map<String, dynamic>> _channels = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _fetchList();
  }

  @override
  void dispose() {
    _tabs.dispose();
    for (final c in [_name, _cat, _photo, _link, _bulkCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _fetchList() async {
    setState(() => _loadingList = true);
    try {
      final res = await http.get(
        Uri.parse('$flaskApi/admin/yt_channels'),
        headers: _adminHeaders,
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() => _channels = List<Map<String, dynamic>>.from(data['yt_channels']));
      }
    } catch (_) {}
    setState(() => _loadingList = false);
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty || _cat.text.trim().isEmpty || _link.text.trim().isEmpty) {
      _snack('Name, category, and link are required.');
      return;
    }
    setState(() => _saving = true);
    try {
      final res = await http.post(
        Uri.parse('$flaskApi/admin/yt_channel/add'),
        headers: _adminHeaders,
        body: json.encode({
          'name':  _name.text.trim(),
          'cat':   _cat.text.trim(),
          'photo': _photo.text.trim(),
          'link':  _link.text.trim(),
        }),
      );
      if (res.statusCode == 201) {
        _snack('YouTube channel added!', success: true);
        for (final c in [_name, _cat, _photo, _link]) c.clear();
        _fetchList();
      } else {
        final d = json.decode(res.body);
        _snack(d['error'] ?? 'Failed to add channel.');
      }
    } catch (e) {
      _snack('Error: $e');
    }
    setState(() => _saving = false);
  }

  Future<void> _submitBulk() async {
    final raw = _bulkCtrl.text.trim();
    if (raw.isEmpty) { _snack('Paste the JSON array first.'); return; }
    List<dynamic> items;
    try {
      items = json.decode(raw) as List;
    } catch (_) {
      _snack('Invalid JSON. Expected a list like [ {"name":"...", "cat":"...", "link":"..."}, ...]');
      return;
    }
    setState(() { _bulkSaving = true; _bulkResult = null; });
    try {
      final res = await http.post(
        Uri.parse('$flaskApi/admin/yt_channel/bulk'),
        headers: _adminHeaders,
        body: json.encode({'channels': items}),
      );
      final d = json.decode(res.body);
      if (res.statusCode == 201) {
        setState(() => _bulkResult = d);
        _snack('Bulk import done!', success: true);
        _fetchList();
      } else {
        _snack(d['error'] ?? 'Bulk import failed.');
      }
    } catch (e) {
      _snack('Error: $e');
    }
    setState(() => _bulkSaving = false);
  }

  Future<void> _delete(int channelId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Channel'),
        content: const Text('Remove this YouTube channel?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Delete', style: TextStyle(color: errorColor)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final res = await http.delete(
        Uri.parse('$flaskApi/admin/yt_channel/$channelId'),
        headers: _adminHeaders,
      );
      if (res.statusCode == 200) {
        _snack('Deleted.', success: true);
        _fetchList();
      } else {
        _snack('Delete failed.');
      }
    } catch (e) {
      _snack('Error: $e');
    }
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
    return Column(children: [
      _FormCard(
        title: 'YouTube Channel Manager',
        icon: Icons.smart_display_rounded,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TabBar(
            controller: _tabs,
            indicatorColor: const Color(0xFFFF0000),
            labelColor: const Color(0xFFFF0000),
            unselectedLabelColor: textSecondary,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            tabs: const [Tab(text: 'Add Single'), Tab(text: 'Bulk Import (JSON)')],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 320,
            child: TabBarView(controller: _tabs, children: [
              // ── Single add ──
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: _field(_name, 'Channel Name *')),
                  const SizedBox(width: 12),
                  Expanded(child: _field(_cat, 'Category *', hint: 'e.g. News, Music')),
                ]),
                const SizedBox(height: 12),
                _field(_link, 'Channel Link *', hint: 'https://youtube.com/@channelname'),
                const SizedBox(height: 12),
                _field(_photo, 'Profile Photo URL', hint: 'https://...'),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _submit,
                    icon: _saving
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                    label: Text(_saving ? 'Adding...' : 'Add Channel',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF0000),
                      disabledBackgroundColor: const Color(0xFFFF0000).withValues(alpha: 0.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                ),
              ]),

              // ── Bulk JSON ──
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: warningColor.withValues(alpha: 0.4)),
                  ),
                  child: const Text(
                    'Paste a JSON array:\n'
                    '[ {"name":"BTV News","cat":"News","link":"https://youtube.com/@btv","photo":""},\n'
                    '  {"name":"Channel 24","cat":"News","link":"https://youtube.com/@ch24"} ]',
                    style: TextStyle(fontSize: 11, color: Color(0xFF92400E), fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: TextField(
                    controller: _bulkCtrl,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: textPrimary),
                    decoration: InputDecoration(
                      hintText: '[ { "name": "...", "cat": "...", "link": "..." }, ... ]',
                      hintStyle: const TextStyle(color: textMuted, fontSize: 12),
                      filled: true,
                      fillColor: background,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderColor)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: accentColor, width: 1.5)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _bulkSaving ? null : _submitBulk,
                      icon: _bulkSaving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.upload_rounded, size: 18, color: Colors.white),
                      label: Text(_bulkSaving ? 'Importing...' : 'Import Channels',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF0000),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  if (_bulkResult != null) ...[
                    const SizedBox(width: 12),
                    Text('✓ Added: ${_bulkResult!['added']}  Skipped: ${_bulkResult!['skipped']}',
                        style: const TextStyle(fontSize: 13, color: successColor, fontWeight: FontWeight.w700)),
                  ],
                ]),
              ]),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 20),
      _FormCard(
        title: 'Existing YouTube Channels',
        icon: Icons.list_alt_rounded,
        child: _loadingList
            ? const Center(child: CircularProgressIndicator())
            : _channels.isEmpty
                ? const Text('No channels yet.', style: TextStyle(color: textSecondary, fontSize: 13))
                : Column(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(children: [
                        Expanded(flex: 3, child: Text('Name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSecondary))),
                        Expanded(flex: 2, child: Text('Category', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSecondary))),
                        SizedBox(width: 60, child: Text('Visits', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSecondary))),
                        SizedBox(width: 50),
                      ]),
                    ),
                    const SizedBox(height: 4),
                    ..._channels.asMap().entries.map((e) {
                      final i = e.key;
                      final ch = e.value;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: i.isEven ? surface : background,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(children: [
                          Expanded(flex: 3, child: Text(ch['name'] ?? '', style: const TextStyle(fontSize: 13, color: textPrimary), overflow: TextOverflow.ellipsis)),
                          Expanded(flex: 2, child: Text(ch['cat'] ?? '', style: const TextStyle(fontSize: 12, color: textSecondary), overflow: TextOverflow.ellipsis)),
                          SizedBox(width: 60, child: Text('${ch['visit_count'] ?? 0}', style: const TextStyle(fontSize: 12, color: textMuted))),
                          SizedBox(
                            width: 50,
                            child: InkWell(
                              onTap: () => _delete(ch['channel_id'] as int),
                              borderRadius: BorderRadius.circular(4),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.delete_outline_rounded, size: 16, color: errorColor),
                              ),
                            ),
                          ),
                        ]),
                      );
                    }),
                  ]),
      ),
    ]);
  }

  Widget _field(TextEditingController ctrl, String label,
      {String? hint, TextInputType keyboardType = TextInputType.text}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textSecondary)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, color: textPrimary),
        decoration: InputDecoration(
          hintText: hint ?? label.replaceAll(' *', ''),
          hintStyle: const TextStyle(color: textMuted, fontSize: 13),
          filled: true,
          fillColor: background,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderColor)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderColor)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: accentColor, width: 1.5)),
        ),
      ),
    ]);
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
