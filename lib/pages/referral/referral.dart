import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_web_dashboard/config.dart';

class DateTimeFormatter {
  static String formatBdTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString); // BD time already stored
      final formatter = DateFormat('dd MMM yyyy, hh:mm a');
      return formatter.format(dt);
    } catch (e) {
      return isoString;
    }
  }
}

class ReferralPage extends StatefulWidget {
  const ReferralPage({super.key});

  @override
  State<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends State<ReferralPage> {
  bool loading = false;
  List<dynamic> results = [];
  Map<String, dynamic> summary = {};
  String currentSort = "most_recent";
  String currentSearchType = "name";

  final _searchController = TextEditingController();

  // Future<void> _load({String? sort, String? search}) async {
  //   setState(() => loading = true);
  //   try {
  //     final response = await http.get(Uri.parse(
  //         "$host/api/referrals/?sort=${sort ?? currentSort}&name=${search ?? ''}"));
  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       setState(() {
  //         summary = data['summary'];
  //         results = data['results'];
  //       });
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context)
  //         .showSnackBar(SnackBar(content: Text("Error: $e")));
  //   } finally {
  //     setState(() => loading = false);
  //   }
  // }

  Future<void> _load({String? sort, String? search, String? searchType}) async {
    setState(() => loading = true);
    try {
      final response = await http.get(Uri.parse(
          "$host/api/referrals/?sort=${sort ?? currentSort}&${searchType ?? 'name'}=${search ?? ''}"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          summary = data['summary'];
          results = data['results'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _updateReferral(int id,
      {String? verification, String? paymentStatus}) async {
    final body = {};
    if (verification != null) body['verification'] = verification;
    if (paymentStatus != null) body['payment_status'] = paymentStatus;

    final response = await http.patch(
      Uri.parse("$host/api/referrals/$id/update/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      _load();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Update failed")));
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Referral Page")),
      body: Column(
        children: [
          // Summary bar
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 6)
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text("Total: ${summary['total'] ?? 0}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("Verified: ${summary['verified'] ?? 0}",
                    style: const TextStyle(color: Colors.green)),
                Text("Unverified: ${summary['unverified'] ?? 0}",
                    style: const TextStyle(color: Colors.red)),
                Text("Waiting: ${summary['waiting'] ?? 0}",
                    style: const TextStyle(color: Colors.orange)),
                Text("Paid: ${summary['paid'] ?? 0}",
                    style: const TextStyle(color: Colors.blue)),
                Text("Unpaid: ${summary['unpaid'] ?? 0}",
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),

          // Search bar
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 12),
          //   child: Row(
          //     children: [
          //       Expanded(
          //         child: TextField(
          //           controller: _searchController,
          //           decoration: const InputDecoration(
          //             labelText: "Search by Name/Phone/UserID",
          //             border: OutlineInputBorder(),
          //             prefixIcon: Icon(Icons.search),
          //           ),
          //         ),
          //       ),
          //       const SizedBox(width: 8),
          //       ElevatedButton(
          //         onPressed: () => _load(search: _searchController.text),
          //         child: const Text("Search"),
          //       ),
          //     ],
          //   ),
          // ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                // Dropdown for search type
                DropdownButton<String>(
                  value: currentSearchType,
                  items: const [
                    DropdownMenuItem(value: "name", child: Text("Name")),
                    DropdownMenuItem(value: "user_id", child: Text("User ID")),
                    DropdownMenuItem(value: "phone", child: Text("Phone")),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => currentSearchType = val);
                    }
                  },
                ),
                const SizedBox(width: 8),

                // TextField for search input
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: "Search by $currentSearchType",
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Search button
                ElevatedButton(
                  onPressed: () {
                    _load(
                        search: _searchController.text,
                        searchType: currentSearchType);
                  },
                  child: const Text("Search"),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text("Most Recent"),
                  selected: currentSort == "most_recent",
                  onSelected: (_) {
                    setState(() => currentSort = "most_recent");
                    _load(sort: "most_recent");
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("Highest Points"),
                  selected: currentSort == "highest_points",
                  onSelected: (_) {
                    setState(() => currentSort = "highest_points");
                    _load(sort: "highest_points");
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("Paid"),
                  selected: currentSort == "paid",
                  onSelected: (_) {
                    setState(() => currentSort = "paid");
                    _load(sort: "paid");
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("Unpaid"),
                  selected: currentSort == "unpaid",
                  onSelected: (_) {
                    setState(() => currentSort = "unpaid");
                    _load(sort: "unpaid");
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Data list
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, i) {
                      final u = results[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        elevation: 4,
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Referrer info
                              Text(
                                  "Referrer: ${u['referrer']['name']} (${u['referrer']['cat_name']})",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue)),
                              Text(
                                "User ID: ${u['referrer']['user_id']}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 255, 0, 212)),
                              ),
                              Text("Phone: ${u['referrer']['phone']}"),
                              Text(
                                  "Location: ${u['referrer']['location_info']['address']}"),

                              const Divider(),

                              // Referred info
                              Text(
                                  "Referred: ${u['referred']['name']} (${u['referred']['cat_name']})",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green)),
                              Text(
                                "User ID: ${u['referred']['user_id']}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 255, 140, 0)),
                              ),
                              Text("Phone: ${u['referred']['phone']}"),
                              Text(
                                  "Location: ${u['referred']['location_info']['address']}"),

                              const Divider(),

                              // Status row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("Points: ${u['points']}"),
                                      Text(
                                          "Created: ${DateTimeFormatter.formatBdTime(u['created_at'])}"),
                                      Text(
                                        u['paid_at'] == null
                                            ? "UNPAID"
                                            : "Paid: ${TimeFormatter.formatBdTime(u['paid_at'])}",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold, // Bold
                                          color: u['paid_at'] == null
                                              ? Colors.red
                                              : Colors.green,
                                        ),
                                        textAlign: TextAlign
                                            .center, // Center alignment
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      // Verification dropdown
                                      DropdownButton<String>(
                                        value: u['verification'],
                                        items: const [
                                          DropdownMenuItem(
                                              value: "waiting",
                                              child: Text("Waiting")),
                                          DropdownMenuItem(
                                              value: "verified",
                                              child: Text("Verified")),
                                          DropdownMenuItem(
                                              value: "unverified",
                                              child: Text("Unverified")),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) {
                                            _updateReferral(u['id'],
                                                verification: val);
                                          }
                                        },
                                      ),
                                      // Payment button
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              u['payment_status'] == "paid"
                                                  ? Colors.green
                                                  : Colors.red,
                                        ),
                                        onPressed: () {
                                          final newStatus =
                                              u['payment_status'] == "paid"
                                                  ? "unpaid"
                                                  : "paid";
                                          _updateReferral(u['id'],
                                              paymentStatus: newStatus);
                                        },
                                        icon: const Icon(
                                          Icons.payment,
                                          color: Colors.black45,
                                        ),
                                        label: Text(
                                          u['payment_status'],
                                          style: const TextStyle(
                                              color:
                                                  Color.fromARGB(115, 0, 0, 0),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
