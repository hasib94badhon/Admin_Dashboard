import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html; // Import for HTML operations
import 'dart:typed_data';
import'package:flutter_web_dashboard/config.dart';

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

    final uri = Uri.parse('$host/insert-cat/'); // API URL
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
            if (selectedOption == "Category") _buildCategoryForm(),
          ],
        ),
      ),
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
