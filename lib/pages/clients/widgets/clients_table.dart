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
import 'package:flutter_web_dashboard/config.dart';

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
      String apiUrl = '$host/get-users/';
      if (userId != null && userId.isNotEmpty) {
        apiUrl += '?search=$userId';
      } else {
        apiUrl += '?sort=${selectedSort.toLowerCase()}';
      }

      // Fetch data from API
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Handle sorting logic for PAID and FREE
        if (responseData.containsKey('users')) {
          List users = responseData['users'];

          // Check selectedSort for PAID or FREE
          if (selectedSort.toLowerCase() == 'paid') {
            setState(() {
              userData = users
                  .where(
                      (user) => user['user_type'] == true) // Filter PAID users
                  .toList();
            });
          } else if (selectedSort.toLowerCase() == 'free') {
            setState(() {
              userData = users
                  .where(
                      (user) => user['user_type'] == false) // Filter FREE users
                  .toList();
            });
          } else {
            setState(() {
              userData = users; // Load all users
            });
          }
        } else {
          setState(() {
            userData = []; // No users found
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

  Future<void> downloadUserData(BuildContext context, String? userId) async {
    try {
      String apiUrl = '$host/download-user/?user_id=$userId';
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final contentDisposition = response.headers['Content-Disposition'];
        final fileName = contentDisposition != null
            ? RegExp(r'filename="(.+)"')
                .firstMatch(contentDisposition)
                ?.group(1)
            : 'user_data.pdf';

        final blob = html.Blob([response.bodyBytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);

        final anchor = html.AnchorElement(href: url)
          ..download = fileName
          ..click();

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

  Future<void> usertoggleStatus(int userId) async {
    final url = Uri.parse('$host/user-toggle-status/$userId/');

    try {
      final response = await http.post(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('User Status updated: ${data['status']}');
      } else {
        print('Failed to toggle user status: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> usertypetoggleStatus(int userId) async {
    final url = Uri.parse('$host/user-type-toggle-status/$userId/');

    try {
      final response = await http.post(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('User Status updated: ${data['user_type']}');
      } else {
        print('Failed to toggle user status: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
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
                    downloadUserData(
                        context, searchUserId); // Pass the context explicitly
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
                      DropdownMenuItem(value: 'paid', child: Text("PAID")),
                      DropdownMenuItem(value: 'free', child: Text("FREE")),
                      DropdownMenuItem(
                          value: 'User_Called',
                          child: Text("Users by most called")),
                    ],
                    onChanged: (newValue) {
                      setState(() {
                        selectedSort = newValue!;
                        isLoading = true;
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
          Container(
            padding: EdgeInsets.all(5),
            color: Colors.pink,
            child: isLoading
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
                            headingRowHeight: 30,
                            horizontalMargin: 12,
                            minWidth: 700,
                            columns: const [
                              DataColumn2(
                                label: Text("UserID"),
                                size: ColumnSize.S,
                              ),
                              DataColumn2(
                                label: Text('Category'),
                                size: ColumnSize.L,
                              ),
                              DataColumn2(
                                label: Text('Name'),
                                size: ColumnSize.L,
                              ),
                              DataColumn2(
                                label: Text('Phone Number'),
                                size: ColumnSize.L,
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
                                      text: userData[index]['user_id']
                                          .toString())),
                                  DataCell(CustomText(
                                      text: userData[index]['cat__cat_name']
                                          .toString())),
                                  DataCell(CustomText(
                                      text:
                                          userData[index]['name'].toString())),
                                  DataCell(CustomText(
                                    text: userData[index]['phone'].toString(),
                                    color:
                                        const Color.fromARGB(255, 1, 104, 54),
                                  )),
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
                                  // DataCell(Container(
                                  //   decoration: BoxDecoration(
                                  //     color: light,
                                  //     borderRadius: BorderRadius.circular(20),
                                  //     border:
                                  //         Border.all(color: active, width: .5),
                                  //   ),
                                  //   padding: const EdgeInsets.symmetric(
                                  //       horizontal: 12, vertical: 6),
                                  //   child: CustomText(
                                  //     text: userData[index]
                                  //         ['user_type'], // Toggle paid status
                                  //     color: active.withOpacity(.7),
                                  //     weight: FontWeight.bold,
                                  //   ),
                                  // )),

                                  DataCell(
                                    GestureDetector(
                                      onTap: () async {
                                        int user_id = userData[index][
                                            'user_id']; // Assuming 'id' is present in your data
                                        await usertypetoggleStatus(
                                            user_id); // Call the API
                                        // Reload or refresh the UI after the API call
                                        setState(() {
                                          userData[index]
                                              ['user_type'] = !userData[
                                                  index][
                                              'user_type']; // Toggle status locally
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: userData[index]['user_type'] ==
                                                  true
                                              ? Colors.green.withOpacity(0.2)
                                              : Colors.red.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        child: Text(
                                          userData[index]['user_type'] == true
                                              ? 'PAID'
                                              : 'FREE',
                                          style: TextStyle(
                                            color: userData[index]
                                                        ['user_type'] ==
                                                    true
                                                ? const Color.fromARGB(
                                                    255, 89, 116, 238)
                                                : const Color.fromARGB(
                                                    255, 147, 154, 247),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // DataCell(
                                  //   StatefulBuilder(
                                  //     builder: (context, setState) {
                                  //       // Variable to track the toggle state
                                  //       bool isActive =
                                  //           true; // Active state toggles between "Active" and "Pause"

                                  //       return Switch(
                                  //         value: isActive,
                                  //         onChanged: (value) {
                                  //           setState(() {
                                  //             isActive = value;
                                  //           });

                                  //           // Add your backend logic here for toggling Active/Pause
                                  //           print(isActive
                                  //               ? "Switched to Active"
                                  //               : "Switched to Pause");
                                  //         },
                                  //         activeColor: Colors
                                  //             .green, // Color for Active state
                                  //         inactiveThumbColor: Colors
                                  //             .red, // Color for Pause state
                                  //         activeTrackColor: Colors.greenAccent,
                                  //         inactiveTrackColor: Colors.redAccent,
                                  //       );
                                  //     },
                                  //   ),
                                  // )
                                  DataCell(
                                    GestureDetector(
                                      onTap: () async {
                                        int categoryId = userData[index][
                                            'user_id']; // Assuming 'id' is present in your data
                                        await usertoggleStatus(
                                            categoryId); // Call the API
                                        // Reload or refresh the UI after the API call
                                        setState(() {
                                          userData[index]['status'] = !userData[
                                                  index][
                                              'status']; // Toggle status locally
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: userData[index]['status'] ==
                                                  true
                                              ? Colors.green.withOpacity(0.2)
                                              : Colors.red.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        child: Text(
                                          userData[index]['status'] == true
                                              ? 'Active'
                                              : 'Inactive',
                                          style: TextStyle(
                                            color: userData[index]['status'] ==
                                                    true
                                                ? Colors.green
                                                : Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
