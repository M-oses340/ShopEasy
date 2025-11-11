import 'dart:ui';
import 'package:ecommerce_admin_app/containers/dashboard_text.dart';
import 'package:ecommerce_admin_app/controllers/auth_service.dart';
import 'package:ecommerce_admin_app/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
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
          _isLoggingOut
              ? const Padding(
            padding: EdgeInsets.all(12),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 30),
            child: Column(
              children: [
                // Dashboard metrics
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

                // Responsive admin action buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = 2; // phones
                      if (constraints.maxWidth > 600) crossAxisCount = 3; // tablets
                      if (constraints.maxWidth > 900) crossAxisCount = 4; // large screens

                      return GridView.count(
                        crossAxisCount: crossAxisCount,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: [
                          _buildHomeButton(context, "Orders", "/orders"),
                          _buildHomeButton(context, "Products", "/products"),
                          _buildHomeButton(context, "Promos", "/promos",
                              arguments: {"promo": true}),
                          _buildHomeButton(context, "Banners", "/promos",
                              arguments: {"promo": false}),
                          _buildHomeButton(context, "Categories", "/category"),
                          _buildHomeButton(context, "Coupons", "/coupons"),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Logout overlay with blur + dim effect
          if (_isLoggingOut)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              color: Colors.black.withValues(alpha: 0),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
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

  // Helper: builds responsive admin buttons with hover effect
  Widget _buildHomeButton(BuildContext context, String name, String route,
      {Object? arguments}) {
    return _HoverableButton(
      name: name,
      onTap: () => Navigator.pushNamed(context, route, arguments: arguments),
    );
  }
}

/// Custom hoverable button widget
class _HoverableButton extends StatefulWidget {
  final String name;
  final VoidCallback onTap;
  const _HoverableButton({required this.name, required this.onTap});

  @override
  State<_HoverableButton> createState() => _HoverableButtonState();
}

class _HoverableButtonState extends State<_HoverableButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isHovering ? 0.15 : 0.1),
              blurRadius: _isHovering ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        transform: Matrix4.identity()
          ..translateByDouble(0.0, _isHovering ? -4.0 : 0.0, 0.0, 1.0), // ✅ fixed
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.deepPurple.withValues(alpha: 0.2),
          onTap: widget.onTap,
          child: Center(
            child: Text(
              widget.name,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
