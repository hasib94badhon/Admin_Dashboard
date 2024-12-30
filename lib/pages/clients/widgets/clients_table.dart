import 'dart:io';

import 'package:data_table_2/data_table_2.dart';
import 'package:open_file/open_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_dashboard/constants/style.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_web_dashboard/widgets/custom_text.dart';
import 'dart:html' as html;

class Clientstable extends StatefulWidget {
  const Clientstable({super.key});

  @override
  State<Clientstable> createState() => _ClientstableState();
}

class _ClientstableState extends State<Clientstable> {
  String selectedSort = 'recent'; // Default sort option
  String? searchUserId; // Input field value for UserID
  List<dynamic> userData = []; // List to store fetched user data
  bool isLoading = true; // Loading state for data fetch

  // Function to fetch and sort user data
  Future<void> fetchData({String? userId}) async {
    setState(() {
      isLoading = true;
    });

    try {
      // Base API URL
      String apiUrl = 'http://127.0.0.1:1200/get-users/';
      if (userId != null && userId.isNotEmpty) {
        apiUrl += '?search=$userId';
      } else {
        apiUrl += '?sort=${selectedSort.toLowerCase()}';
      }

      // Fetch data from API
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Handle specific user vs multiple users
        if (userId != null &&
            userId.isNotEmpty &&
            responseData.containsKey('user')) {
          setState(() {
            userData = [responseData['user']]; // Single user data as a list
          });
        } else if (responseData.containsKey('users')) {
          setState(() {
            userData = responseData['users']; // Full list of users
          });
        } else {
          setState(() {
            userData = []; // No data found
          });
        }
      } else {
        throw Exception("Failed to load data");
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        userData = [];
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> downloadUserData(BuildContext context) async {
    try {
      // Define the API URL
      String apiUrl = 'http://127.0.0.1:1200/get-users/?download=true';

      // Make an HTTP GET request
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        // Create a Blob and trigger a download using the web
        final blob = html.Blob([response.bodyBytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);

        // Create an anchor element and trigger a download
        final anchor = html.AnchorElement(href: url)
          ..download = "user_data.pdf"
          ..click();

        // Clean up the object URL
        html.Url.revokeObjectUrl(url);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download started successfully!')),
        );

        print("Download triggered successfully.");
      } else {
        throw Exception(
            "Failed to download PDF. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error downloading or saving PDF: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error downloading or saving PDF: $e")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData(); // Initial fetch when the widget loads
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Search Bar with Search Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      searchUserId = value; // Update search input
                      if (value.isEmpty) {
                        fetchData(); // Reload data when input is cleared
                      }
                    },
                    decoration: InputDecoration(
                      hintText: "Search by UserID",
                      filled: true,
                      fillColor: Colors.blue,
                      prefixIcon: const Icon(Icons.search, color: Colors.black),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    // Fetch specific user data by ID
                    if (searchUserId != null && searchUserId!.isNotEmpty) {
                      fetchData(userId: searchUserId);
                    }
                  },
                  icon: const Icon(Icons.search, color: Colors.white),
                  label: const Text("Search"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                    backgroundColor: active,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 3,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    downloadUserData(context); // Pass the context explicitly
                  },
                  icon: const Icon(Icons.download, color: Colors.white),
                  label: const Text("Download"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                    backgroundColor: const Color.fromARGB(255, 25, 192, 81),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 3,
                  ),
                ),
              ],
            ),
          ),

          // Sorting Dropdowns
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Main Sort Dropdown
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedSort,
                    decoration: InputDecoration(
                      //labelText: "Sort By",
                      filled: true,
                      fillColor: Colors.green,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'recent', child: Text("Most recent")),
                      DropdownMenuItem(
                          value: 'Category', child: Text("Users by category")),
                      DropdownMenuItem(
                          value: 'User Type', child: Text("Paid/Free")),
                      DropdownMenuItem(
                          value: 'User_Called',
                          child: Text("Users by most called")),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedSort = value!;
                      });
                      fetchData(); // Fetch sorted data
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // User Data Table
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : userData.isEmpty
                  ? const Center(child: Text("No data available"))
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                            color: active.withOpacity(.4), width: .5),
                        boxShadow: [
                          BoxShadow(
                            offset: const Offset(0, 6),
                            color: lightGrey.withOpacity(.1),
                            blurRadius: 12,
                          )
                        ],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 30),
                      child: SizedBox(
                        height: (60 * 7) + 40,
                        child: DataTable2(
                          columnSpacing: 12,
                          dataRowHeight: 60,
                          headingRowHeight: 40,
                          horizontalMargin: 12,
                          minWidth: 700,
                          columns: const [
                            DataColumn2(
                              label: Text("UserID"),
                              size: ColumnSize.L,
                            ),
                            DataColumn(
                              label: Text('Category'),
                            ),
                            DataColumn(
                              label: Text('User called'),
                            ),
                            DataColumn(
                              label: Text('User Type'),
                            ),
                            DataColumn(
                              label: Text('Status'),
                            ),
                          ],
                          rows: List<DataRow>.generate(
                            userData.length,
                            (index) => DataRow(
                              cells: [
                                DataCell(CustomText(
                                    text:
                                        userData[index]['user_id'].toString())),
                                DataCell(CustomText(
                                    text:
                                        userData[index]['cat_id'].toString())),
                                DataCell(Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: Colors.deepOrange,
                                      size: 18,
                                    ),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    CustomText(
                                      text: userData[index]['user_called']
                                          .toString(),
                                    )
                                  ],
                                )),
                                DataCell(Container(
                                  decoration: BoxDecoration(
                                    color: light,
                                    borderRadius: BorderRadius.circular(20),
                                    border:
                                        Border.all(color: active, width: .5),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  child: CustomText(
                                    text: userData[index]
                                        ['user_type'], // Toggle paid status
                                    color: active.withOpacity(.7),
                                    weight: FontWeight.bold,
                                  ),
                                )),
                                DataCell(
                                  StatefulBuilder(
                                    builder: (context, setState) {
                                      // Variables to control button states
                                      bool isPlayActive =
                                          true; // Initial active button (Play or Pause)
                                      bool isDeleteLocked =
                                          true; // Initial state for Delete button safety lock

                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Play Button
                                          ElevatedButton.icon(
                                            onPressed: isPlayActive
                                                ? null
                                                : () {
                                                    setState(() {
                                                      isPlayActive = true;
                                                    });
                                                    print(
                                                        "Play action triggered");
                                                  },
                                            icon: const Icon(Icons.play_arrow),
                                            label: const Text("Play"),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ).copyWith(
                                              backgroundColor:
                                                  MaterialStateProperty
                                                      .resolveWith<Color>(
                                                (states) => isPlayActive
                                                    ? Colors.green
                                                    : Colors.green
                                                        .withOpacity(0.5),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),

                                          // Pause Button
                                          ElevatedButton.icon(
                                            onPressed: isPlayActive
                                                ? () {
                                                    setState(() {
                                                      isPlayActive = false;
                                                    });
                                                    print(
                                                        "Pause action triggered");
                                                  }
                                                : null,
                                            icon: const Icon(Icons.pause),
                                            label: const Text("Pause"),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ).copyWith(
                                              backgroundColor:
                                                  MaterialStateProperty
                                                      .resolveWith<Color>(
                                                (states) => !isPlayActive
                                                    ? Colors.blue
                                                    : Colors.blue
                                                        .withOpacity(0.5),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),

                                          // Delete Button
                                          ElevatedButton.icon(
                                            onPressed: isDeleteLocked
                                                ? () {
                                                    setState(() {
                                                      isDeleteLocked = false;
                                                    });
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                            "Safety lock removed. Tap Delete to proceed."),
                                                      ),
                                                    );
                                                  }
                                                : () {
                                                    print(
                                                        "Delete action triggered");
                                                  },
                                            icon: Icon(
                                              isDeleteLocked
                                                  ? Icons.lock
                                                  : Icons.delete_forever,
                                            ),
                                            label: Text(isDeleteLocked
                                                ? "Unlock"
                                                : "Delete"),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: isDeleteLocked
                                                  ? Colors.grey
                                                  : Colors.red,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

          // Download User Data Section
          // Container(
          //   decoration: BoxDecoration(
          //     color: Colors.white,
          //     borderRadius: BorderRadius.circular(8),
          //     border: Border.all(color: active.withOpacity(.4), width: .5),
          //     boxShadow: [
          //       BoxShadow(
          //         offset: const Offset(0, 6),
          //         color: lightGrey.withOpacity(.1),
          //         blurRadius: 12,
          //       )
          //     ],
          //   ),
          //   padding: const EdgeInsets.all(16),
          //   margin: const EdgeInsets.only(bottom: 30),
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       const CustomText(
          //         text: "Download User Data",
          //         size: 18,
          //         weight: FontWeight.bold,
          //         color: Colors.black87,
          //       ),
          //       const SizedBox(height: 16),
          //       Row(
          //         children: [
          //           Expanded(
          //             child: TextField(
          //               decoration: InputDecoration(
          //                 hintText: "Enter UserID",
          //                 filled: true,
          //                 fillColor: light,
          //                 prefixIcon:
          //                     const Icon(Icons.search, color: Colors.grey),
          //                 border: OutlineInputBorder(
          //                   borderRadius: BorderRadius.circular(8),
          //                   borderSide: BorderSide.none,
          //                 ),
          //               ),
          //             ),
          //           ),
          //           const SizedBox(width: 16),
          //           ElevatedButton.icon(
          //             onPressed: () {
          //               // Handle download functionality here
          //             },
          //             icon: const Icon(Icons.download, color: Colors.white),
          //             label: const Text("Download"),
          //             style: ElevatedButton.styleFrom(
          //               padding: const EdgeInsets.symmetric(
          //                   horizontal: 24, vertical: 16),
          //               backgroundColor: active,
          //               shape: RoundedRectangleBorder(
          //                 borderRadius: BorderRadius.circular(8),
          //               ),
          //               elevation: 3,
          //             ),
          //           ),
          //         ],
          //       ),
          //       const SizedBox(height: 8),
          //       const Text(
          //         "Enter a UserID to download all related data.",
          //         style: TextStyle(color: Colors.grey),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }
}
