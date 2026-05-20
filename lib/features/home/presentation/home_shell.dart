import 'package:flutter/material.dart';

import '../../../core/models/app_user.dart';
import '../../buyer_marketplace/presentation/marketplace_page.dart';
import '../../cart/presentation/cart_page.dart';
import '../../delivery/presentation/delivery_page.dart';
import '../../notifications/presentation/notifications_page.dart';
import '../../orders/presentation/orders_page.dart';
import '../../profile/presentation/profile_page.dart';
import '../../seller_center/presentation/seller_dashboard_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.user});

  final AppUser user;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final config = _navigationForRole(widget.user.role);

    return Scaffold(
      body: SafeArea(child: config.pages[_currentIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        destinations: config.destinations,
        onDestinationSelected: (value) {
          setState(() => _currentIndex = value);
        },
      ),
    );
  }

  _ShellConfig _navigationForRole(AppRole role) {
    switch (role) {
      case AppRole.seller:
        return _ShellConfig(
          pages: const [
            MarketplacePage(),
            OrdersPage(),
            SellerDashboardPage(),
            NotificationsPage(),
            ProfilePage(),
          ],
          destinations: const [
            NavigationDestination(icon: Icon(Icons.storefront), label: 'Market'),
            NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Orders'),
            NavigationDestination(icon: Icon(Icons.eco), label: 'Seller'),
            NavigationDestination(icon: Icon(Icons.notifications), label: 'Alerts'),
            NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
          ],
        );
      case AppRole.rider:
        return _ShellConfig(
          pages: const [
            DeliveryPage(mode: DeliveryMode.available),
            DeliveryPage(mode: DeliveryMode.assigned),
            OrdersPage(),
            NotificationsPage(),
            ProfilePage(),
          ],
          destinations: const [
            NavigationDestination(icon: Icon(Icons.route), label: 'Requests'),
            NavigationDestination(icon: Icon(Icons.two_wheeler), label: 'Assigned'),
            NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Orders'),
            NavigationDestination(icon: Icon(Icons.notifications), label: 'Alerts'),
            NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
          ],
        );
      case AppRole.admin:
      case AppRole.buyer:
        return _ShellConfig(
          pages: const [
            MarketplacePage(),
            CartPage(),
            OrdersPage(),
            NotificationsPage(),
            ProfilePage(),
          ],
          destinations: const [
            NavigationDestination(icon: Icon(Icons.storefront), label: 'Market'),
            NavigationDestination(icon: Icon(Icons.shopping_cart), label: 'Cart'),
            NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Orders'),
            NavigationDestination(icon: Icon(Icons.notifications), label: 'Alerts'),
            NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
          ],
        );
    }
  }
}

class _ShellConfig {
  const _ShellConfig({
    required this.pages,
    required this.destinations,
  });

  final List<Widget> pages;
  final List<NavigationDestination> destinations;
}
