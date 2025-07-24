import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vendor/Pages/login_page.dart';
import 'package:vendor/Pages/orders_list.dart';
import 'package:vendor/Pages/product_dashboard.dart';
import 'package:vendor/Pages/profile_screen.dart';
import 'package:vendor/Pages/vendor_tickets_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectedIndex = 0;

  final List<String> menuItems = ["Orders", "Products", "My Profile", "Queries?"];

   List<Widget> screens = [];

  @override
  void initState() {
    super.initState();
    loadVendorName();
  }

  Future<void> loadVendorName() async {
    final prefs = await SharedPreferences.getInstance();
    final vendorName = prefs.getString('vendorName') ?? 'Unknown Vendor';

    setState(() {
      screens = [
        const OrdersScreen(),
        ProductsListScreen(vendorName: vendorName),
        const MyProfileScreen(),
        VendorTicketList(vendorName: vendorName,)
      ];
    });
  }

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
          BottomNavigationBarItem(icon: Icon(Icons.message), label: "Queries?"),
        ],
      )
          : null,
    );
  }
}
