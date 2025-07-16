import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:vendor/Pages/login_page.dart';
import 'package:vendor/Pages/orders_list.dart';
import 'package:vendor/Pages/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectedIndex = 0;

  final List<String> menuItems = ["Home", "Orders", "My Profile"];

  final List<Widget> screens = const [
    Center(child: Text("Home Screen", style: TextStyle(fontSize: 24))),
    OrdersScreen(),
    MyProfileScreen()
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      body: isMobile
          ? screens[selectedIndex] // Main content for mobile
          : Row(
        children: [
          // Sidebar
          Container(
            width: 200,
            color: Colors.black,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DrawerHeader(
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/images/buybill_black.svg',
                      height: 80,
                      width: 80,
                    ),
                  ),
                ),
                ...List.generate(menuItems.length, (index) {
                  final isSelected = selectedIndex == index;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        selectedIndex = index;
                      });
                    },
                    child: Container(
                      color: isSelected ? Colors.blueGrey : Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      child: Text(
                        menuItems[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[300],
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: screens[selectedIndex],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isMobile
          ? BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) => setState(() => selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: "Orders"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      )
          : null,
    );
  }
}
