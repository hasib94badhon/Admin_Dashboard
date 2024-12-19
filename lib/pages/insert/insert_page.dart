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

class InsertPage extends StatefulWidget {
  const InsertPage({Key? key}) : super(key: key);

  @override
  _InsertPageState createState() => _InsertPageState();
}

class _InsertPageState extends State<InsertPage> {
  String? selectedOption;
  TextEditingController catNameController = TextEditingController();
  html.File? selectedImage; // Store the selected image
  Uint8List? imageBytes; // Store image bytes for display
  html.File? uploadedFile;

  void pickFile() {
    html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = ".xlsx, .xls";
    uploadInput.click();
    uploadInput.onChange.listen((e) {
      final file = uploadInput.files!.first;
      final reader = html.FileReader();

      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((e) {
        setState(() {
          uploadedFile = file;
        });
      });
    });
  }

  Future<void> uploadFile() async {
    final formData = html.FormData();
    formData.appendBlob('file', uploadedFile!);

    final uri = Uri.parse("http://127.0.0.1:1200/upload-users/");
    try {
      final request = html.HttpRequest();
      request.open("POST", uri.toString());
      request.setRequestHeader("enctype", "multipart/form-data");

      // Log request state
      print("Sending request to $uri");

      request.onLoadEnd.listen((event) {
        if (request.status == 201) {
          print("Success: ${request.responseText}");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File uploaded successfully!')),
          );
        } else {
          print("Error ${request.status}: ${request.responseText}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: ${request.responseText}')),
          );
        }
      });

      request.send(formData);
    } catch (e) {
      print("Request failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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

    final uri = Uri.parse('http://127.0.0.1:1200/insert-cat/'); // API URL
    var request = http.MultipartRequest('POST', uri)
      ..fields['cat_name'] = catNameController.text
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
              items: ["User", "Category"].map((String value) {
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
          onPressed: pickFile,
          icon: const Icon(Icons.upload_file),
          label: const Text("Upload Excel Sheet"),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: uploadFile,
          child: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.black38),
            child: Text("PUSH"),
          ),
        )
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
}
