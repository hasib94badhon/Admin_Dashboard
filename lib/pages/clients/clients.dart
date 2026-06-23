import 'package:flutter/material.dart';
import 'package:flutter_web_dashboard/pages/clients/widgets/clients_table.dart';

class ClientsPage extends StatelessWidget {
  const ClientsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 8, bottom: 16),
      child: Clientstable(),
    );
  }
}
