import 'package:flutter/material.dart';
import 'info_card_small.dart';


class OverviewCardsSmallScreen extends StatelessWidget {
  const OverviewCardsSmallScreen({super.key});


  @override
  Widget build(BuildContext context) {
   double width = MediaQuery.of(context).size.width;

    return  SizedBox(
      height: 400,
      child: Column(
        children: [
          InfoCardSmall(
                        title: "Total Users",
                        value: "564",
                        onTap: () {},
                        isActive: true,
                      ),
                      SizedBox(
                        height: width / 64,
                      ),
                      InfoCardSmall(
                        title: "Total Categories",
                        value: "17",
                        onTap: () {},
                      ),
                     SizedBox(
                        height: width / 64,
                      ),
                          InfoCardSmall(
                        title: "Active Users",
                        value: "125",
                        onTap: () {},
                      ),
                      SizedBox(
                        height: width / 64,
                      ),
                      InfoCardSmall(
                        title: "Paid Users",
                        value: "32",
                        onTap: () {},
                      ),
                  
        ],
      ),
    );
  }
}