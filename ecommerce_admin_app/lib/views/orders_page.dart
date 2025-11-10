import 'package:ecommerce_admin_app/controllers/db_service.dart';
import 'package:ecommerce_admin_app/models/orders_model.dart';
import 'package:ecommerce_admin_app/utils/date_formatter.dart';
import 'package:flutter/material.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  bool _isLoading = false;

  // -------------------- Status Chip --------------------
  Widget orderStatusChip(String status) {
    final Map<String, Color> colors = {
      "PAID": Colors.green,
      "ON_THE_WAY": Colors.orange,
      "DELIVERED": Colors.blue,
      "CANCELLED": Colors.red,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors[status]?.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.replaceAll("_", " "),
        style: TextStyle(
          color: colors[status],
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // -------------------- Summary Box --------------------
  Widget summaryBox(String label, int value, Color color) {
    return Container(
      height: 70,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500, color: color),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "$value",
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------- Modify Order Dialog --------------------
  Future<void> _modifyOrder(BuildContext parentContext, OrdersModel order) async {
    await showDialog(
      context: parentContext,
      builder: (context) {
        return AlertDialog(
          title: const Text("Modify this order"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text("Choose status to set:"),
              ),
              TextButton(
                onPressed: () => _updateStatus(order, "PAID"),
                child: const Text("Order Paid"),
              ),
              TextButton(
                onPressed: () => _updateStatus(order, "ON_THE_WAY"),
                child: const Text("Order Shipped"),
              ),
              TextButton(
                onPressed: () => _updateStatus(order, "DELIVERED"),
                child: const Text("Order Delivered"),
              ),
              TextButton(
                onPressed: () => _updateStatus(order, "CANCELLED"),
                child: const Text("Cancel Order"),
              ),
            ],
          ),
        );
      },
    );
  }

  // -------------------- Update Order Status --------------------
  Future<void> _updateStatus(OrdersModel order, String status) async {
    setState(() => _isLoading = true);

    try {
      // ✅ Named parameters match DbService
      await DbService.instance.updateOrderStatus(
        docId: order.id,
        data: {"status": status},
      );

      if (!mounted) return;

      Navigator.of(context).pop(); // Close modify dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Order status updated to $status")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // -------------------- Main Build --------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Orders Dashboard"),
      ),
      body: Stack(
        children: [
          StreamBuilder(
            stream: DbService.instance.readOrders(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text("Error loading orders"));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No orders found"));
              }

              final orders = OrdersModel.fromJsonList(snapshot.data!.docs);

              // Compute status counts
              final Map<String, int> statusCounts = {
                "PAID": 0,
                "ON_THE_WAY": 0,
                "DELIVERED": 0,
                "CANCELLED": 0,
              };
              for (var o in orders) {
                statusCounts[o.status] = (statusCounts[o.status] ?? 0) + 1;
              }

              return Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    // Summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.deepPurple.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Order Summary",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 10),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: 2.2,
                            children: [
                              summaryBox(
                                  "Cancelled", statusCounts["CANCELLED"]!, Colors.red),
                              summaryBox(
                                  "On the Way", statusCounts["ON_THE_WAY"]!, Colors.orange),
                              summaryBox("Paid", statusCounts["PAID"]!, Colors.green),
                              summaryBox(
                                  "Delivered", statusCounts["DELIVERED"]!, Colors.blue),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Divider(thickness: 1),
                    const SizedBox(height: 10),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Recent Orders",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Expanded(
                      child: ListView.builder(
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 2),
                            child: ListTile(
                              onTap: () => Navigator.pushNamed(
                                context,
                                "/view_order",
                                arguments: order,
                              ),
                              title: Text("Order by ${order.name}",
                                  style:
                                  const TextStyle(fontWeight: FontWeight.w500)),
                              subtitle: Text(
                                  "Ordered ${formatRelativeTime(order.created_at)}",
                                  style: const TextStyle(fontSize: 13)),
                              trailing: orderStatusChip(order.status),
                              onLongPress: () => _modifyOrder(context, order),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
