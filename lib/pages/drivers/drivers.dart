import 'package:flutter/material.dart';
import 'package:flutter_web_dashboard/pages/drivers/widgets/cat_table.dart';

class DriversPage extends StatelessWidget {
  const DriversPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 8, bottom: 16),
      child: CatTable(),
    );
  }
}
