import 'dart:ui';
import 'package:ecommerce_admin_app/containers/dashboard_text.dart';
import 'package:ecommerce_admin_app/containers/home_button.dart';
import 'package:ecommerce_admin_app/controllers/auth_service.dart';
import 'package:ecommerce_admin_app/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome>
    with SingleTickerProviderStateMixin {
  bool _isLoggingOut = false;

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    setState(() => _isLoggingOut = true);

    try {
      // Clean up provider state
      Provider.of<AdminProvider>(context, listen: false).cancelProvider();
      await AuthService().logout();

      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logout failed: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _isLoggingOut ? null : () => _handleLogout(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 30),
            child: Column(
              children: [
                Container(
                  height: 260,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Consumer<AdminProvider>(
                    builder: (context, value, child) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        DashboardText(
                            keyword: "Total Categories",
                            value: "${value.categories.length}"),
                        DashboardText(
                            keyword: "Total Products",
                            value: "${value.products.length}"),
                        DashboardText(
                            keyword: "Total Orders",
                            value: "${value.totalOrders}"),
                        DashboardText(
                            keyword: "Order Not Shipped Yet",
                            value: "${value.orderPendingProcess}"),
                        DashboardText(
                            keyword: "Orders Shipped",
                            value: "${value.ordersOnTheWay}"),
                        DashboardText(
                            keyword: "Orders Delivered",
                            value: "${value.ordersDelivered}"),
                        DashboardText(
                            keyword: "Orders Cancelled",
                            value: "${value.ordersCancelled}"),
                      ],
                    ),
                  ),
                ),

                // Admin action buttons
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    HomeButton(
                      onTap: () => Navigator.pushNamed(context, "/orders"),
                      name: "Orders",
                    ),
                    HomeButton(
                      onTap: () => Navigator.pushNamed(context, "/products"),
                      name: "Products",
                    ),
                    HomeButton(
                      onTap: () => Navigator.pushNamed(context, "/promos",
                          arguments: {"promo": true}),
                      name: "Promos",
                    ),
                    HomeButton(
                      onTap: () => Navigator.pushNamed(context, "/promos",
                          arguments: {"promo": false}),
                      name: "Banners",
                    ),
                    HomeButton(
                      onTap: () => Navigator.pushNamed(context, "/category"),
                      name: "Categories",
                    ),
                    HomeButton(
                      onTap: () => Navigator.pushNamed(context, "/coupons"),
                      name: "Coupons",
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Logout overlay with blur effect
          if (_isLoggingOut)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              color: Colors.black.withValues(alpha: 0), // transparent base
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5), // dimmed overlay
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
