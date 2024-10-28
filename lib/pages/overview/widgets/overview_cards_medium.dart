import 'package:flutter/material.dart';
import 'package:flutter_web_dashboard/pages/overview/widgets/info_card.dart';


class OverviewCardsMediumScreen extends StatelessWidget {
  const OverviewCardsMediumScreen({super.key});


  @override
  Widget build(BuildContext context) {
   double width = MediaQuery.of(context).size.width;

    return  Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
                  children: [
                    InfoCard(
                      title: "Total Users",
                      value: "564",
                      onTap: () {},
                  topColor: Colors.orange,

                    ),
                    SizedBox(
                      width: width / 64,
                    ),
                    InfoCard(
                      title: "Total Categories",
                      value: "17",
                  topColor: Colors.lightGreen,

                      onTap: () {},
                    ),
                  
                  ],
                ),
            SizedBox(
                      height: width / 64,
                    ),
                  Row(
                  children: [
             
                    InfoCard(
                      title: "Active Users",
                      value: "125",
                  topColor: Colors.redAccent,

                      onTap: () {},
                    ),
                    SizedBox(
                      width: width / 64,
                    ),
                    InfoCard(
                      title: "Paid Users",
                      value: "32",
                      onTap: () {},
                    ),
                
                  ],
                ),
      ],
    );
  }
}