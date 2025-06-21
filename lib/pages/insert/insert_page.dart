import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_dashboard/constants/controllers.dart';
import 'package:flutter_web_dashboard/helpers/reponsiveness.dart';
import 'package:flutter_web_dashboard/widgets/custom_text.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:html' as html; // Import this package for HTML operations
import 'dart:typed_data';
<<<<<<< HEAD
import 'package:flutter_web_dashboard/config.dart';
=======
import'package:flutter_web_dashboard/config.dart';
>>>>>>> 6c736d0932110085b7e83a0d2968fbbc51a94ad9

class InsertPage extends StatefulWidget {
  const InsertPage({Key? key}) : super(key: key);

  @override
  _InsertPageState createState() => _InsertPageState();
}

class _InsertPageState extends State<InsertPage> {
  String? selectedOption;
  String? selectedtype;
  TextEditingController catNameController = TextEditingController();
  TextEditingController serviceController = TextEditingController();
  TextEditingController shopController = TextEditingController();
  html.File? selectedImage; // Store the selected image
  Uint8List? imageBytes; // Store image bytes for display
  PlatformFile? selectedFile; // Store the file data
  bool isUploading = false;

// Function to pick an Excel file
  Future<void> pickExcelFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'xlsm'], // Restrict to Excel files
      withData: true, // Important: This ensures `bytes` is populated
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        selectedFile = result.files.first; // Store the first file
      });
    } else {
      setState(() {
        selectedFile = null;
      });
    }
  }

  // Function to upload the Excel file to the Django backend
  Future<void> uploadExcelFile() async {
    if (selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an Excel file to upload.")),
      );
      return;
    }

    setState(() {
      isUploading = true;
    });

<<<<<<< HEAD
    final uri = Uri.parse("$host/upload-users/"); // API endpoint
=======
    final uri =
        Uri.parse("$host/upload-users/"); // API endpoint
>>>>>>> 6c736d0932110085b7e83a0d2968fbbc51a94ad9
    var request = http.MultipartRequest("POST", uri);

    // Add file data as bytes
    request.files.add(http.MultipartFile.fromBytes(
      "file",
      selectedFile!.bytes!, // Use `bytes` property for the web platform
      filename: selectedFile!.name,
    ));

    try {
      var response = await request.send();
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Data uploaded successfully!")),
        );
      } else {
        var responseBody = await response.stream.bytesToString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: $responseBody")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  // Function to upload hotline numbers (similar to user upload)
  Future<void> uploadHotlineNumbers() async {
    if (selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an Excel file to upload.")),
      );
      return;
    }

    setState(() {
      isUploading = true;
    });

    final uri = Uri.parse("$host/upload-hotline-numbers/"); // API endpoint
    var request = http.MultipartRequest("POST", uri);

    // Add file data as bytes
    request.files.add(http.MultipartFile.fromBytes(
      "file",
      selectedFile!.bytes!, // Use `bytes` property for the web platform
      filename: selectedFile!.name,
    ));

    try {
      var response = await request.send();
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Hotline numbers uploaded successfully!")),
        );
      } else {
        var responseBody = await response.stream.bytesToString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: $responseBody")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  Future<void> uploadapps() async {
    if (selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an Excel file to upload.")),
      );
      return;
    }

    setState(() {
      isUploading = true;
    });

    final uri = Uri.parse("$host/upload-apps/"); // API endpoint
    var request = http.MultipartRequest("POST", uri);

    // Add file data as bytes
    request.files.add(http.MultipartFile.fromBytes(
      "file",
      selectedFile!.bytes!, // Use `bytes` property for the web platform
      filename: selectedFile!.name,
    ));

    try {
      var response = await request.send();
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Apps are uploaded successfully!")),
        );
      } else {
        var responseBody = await response.stream.bytesToString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: $responseBody")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  // Function to pick an image using HTML input (works for web)
  Future<void> pickImage() async {
    // Create an HTML input element to choose files
    html.FileUploadInputElement input = html.FileUploadInputElement();
    input.accept = 'image/*';
    input.click();

    input.onChange.listen((e) async {
      final files = input.files;
      if (files!.isEmpty) return;

      setState(() {
        selectedImage = files[0]; // Store the selected file
      });

      // Read the file as bytes using FileReader
      final reader = html.FileReader();
      reader.readAsArrayBuffer(selectedImage!);

      reader.onLoadEnd.listen((e) {
        setState(() {
          imageBytes =
              reader.result as Uint8List; // Store image bytes for later use
        });
      });
    });
  }

  // Function to upload the data through API
  Future<void> submitData() async {
    if (catNameController.text.isEmpty || selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields are required!")),
      );
      return;
    }

<<<<<<< HEAD
=======
    bool isService = selectedtype == 'service';
    bool isShop = selectedtype == 'shop';

>>>>>>> 6c736d0932110085b7e83a0d2968fbbc51a94ad9
    final uri = Uri.parse('$host/insert-cat/'); // API URL
    var request = http.MultipartRequest('POST', uri)
      ..fields['cat_name'] = catNameController.text
      ..fields['yes_service'] = isService.toString()
      ..fields['yes_shop'] = isShop.toString()

      ..files.add(await http.MultipartFile.fromBytes(
        'cat_logo',
        imageBytes!, // Use the bytes to send the file
        filename: selectedImage!.name,
      ));

    try {
      var response = await request.send();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Category created successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to create category!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error occurred while inserting data!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Insert"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select an option:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              isExpanded: true,
              value: selectedOption,
              items: ["User", "Category", "Hotline Numbers", "Apps", "FB Page"]
                  .map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedOption = value;
                });
              },
              hint: const Text("Choose an option"),
            ),
            const SizedBox(height: 20),
            if (selectedOption == "User") _buildUserForm(),
            if (selectedOption == "Category") _buildCategoryForm(),
            if (selectedOption == "Hotline Numbers") _buildHotlineNumbersForm(),
            if (selectedOption == "Apps") _buildAppsForm(),
            // if (selectedOption == "FB Page") _buildfbForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Upload User Data",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: pickExcelFile,
          icon: const Icon(Icons.upload_file),
          label: const Text("Select Excel Sheet"),
        ),
        const SizedBox(height: 10),
        selectedFile != null
            ? Text(
                "Selected File: ${selectedFile!.name}",
                style: const TextStyle(color: Colors.green),
              )
            : const Text(
                "No file selected",
                style: TextStyle(color: Colors.red),
              ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: isUploading ? null : uploadExcelFile,
          child: isUploading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("Upload Data"),
        ),
      ],
    );
  }

  Widget _buildHotlineNumbersForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Upload Hotline Numbers",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),
        const Text(
          """
  To ensure a smooth and accurate data upload from your excel file to our database, please adhere to the following guidelines:

1. Required columns: your excel sheet must contain precisely four columns with these headers: 'name', 'phone', 'category', and 'photo'.

2. Data validation: for successful upload, each row needs complete data in the 'name', 'phone', and 'category' columns. any row missing information in these essential fields will be automatically excluded.

3. Lowercase content & Sheet name: all words within the cells of your excel sheet should be lowercase. additionally, please ensure the sheet name in your excel file is  "data" """,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w500, color: Colors.red),
        ),
        const SizedBox(height: 30),
        ElevatedButton.icon(
          onPressed: pickExcelFile,
          icon: const Icon(Icons.upload_file),
          label: const Text("Select Excel Sheet"),
        ),
        const SizedBox(height: 10),
        selectedFile != null
            ? Text(
                "Selected File: ${selectedFile!.name}",
                style: const TextStyle(color: Colors.green),
              )
            : const Text(
                "No file selected",
                style: TextStyle(color: Colors.red),
              ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: isUploading ? null : uploadHotlineNumbers,
          child: isUploading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("Upload Hotline Numbers"),
        ),
      ],
    );
  }

  Widget _buildCategoryForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Category Name",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: catNameController,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: "Enter Name",
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 20),
        DropdownButton<String>(
              isExpanded: true,
              value: selectedtype,
              items: ["service", "shop"].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedtype= value;
                });
              },
              hint: const Text("Choose an type"),
            ),
        const SizedBox(height: 20),
        const Text(
          "Upload Category Picture",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: pickImage,
          icon: const Icon(Icons.image),
          label: const Text("Upload Picture"),
        ),
        const SizedBox(height: 10),
        imageBytes != null
            ? Image.memory(
                imageBytes!,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              )
            : const Text("No image selected"),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
              color: Colors.lightBlue,
              border: Border.all(width: 2),
              borderRadius: BorderRadius.circular(35)),
          child: ElevatedButton.icon(
            onPressed: submitData,
            icon: const Icon(Icons.upload),
            label: const Text("CREATE"),
          ),
        ),
      ],
    );
  }

  Widget _buildAppsForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Upload Apps links",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),
        const Text(
          """
  To ensure a smooth and accurate apps data upload from your excel file to our database, please adhere to the following guidelines:
1. Required columns: your excel sheet must contain precisely four columns with these headers: 'name', 'web','address', 'category', and 'photo'.
2. Data validation: for successful upload, each row needs complete data in the 'name', 'web', and 'category' columns. any row missing information in these essential fields will be automatically excluded.
3. Lowercase content & Sheet name: all words within the cells of your excel sheet should be lowercase. additionally, please ensure the sheet name in your excel file is  "apps" """,
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500, color: Colors.red),
        ),
        const SizedBox(height: 30),
        ElevatedButton.icon(
          onPressed: pickExcelFile,
          icon: const Icon(Icons.upload_file),
          label: const Text("Select Excel Sheet"),
        ),
        const SizedBox(height: 10),
        selectedFile != null
            ? Text(
                "Selected File: ${selectedFile!.name}",
                style: const TextStyle(color: Colors.green),
              )
            : const Text(
                "No file selected",
                style: TextStyle(color: Colors.red),
              ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: isUploading ? null : uploadapps,
          child: isUploading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("Upload Apps"),
        ),
      ],
    );
  }
}
