import 'package:ecommerce_admin_app/controllers/db_service.dart';
import 'package:ecommerce_admin_app/models/orders_model.dart';
import 'package:ecommerce_admin_app/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_admin_app/utils/date_formatter.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  totalQuantityCalculator(List<OrderProductModel> products) {
    int qty = 0;
    products.map((e) => qty += e.quantity).toList();
    return qty;
  }

  Widget statusIcon(String status) {
    if (status == "PAID") {
      return statusContainer(
          text: "PAID", bgColor: Colors.lightGreen, textColor: Colors.white);
    }
    if (status == "ON_THE_WAY") {
      return statusContainer(
          text: "ON THE WAY", bgColor: Colors.yellow, textColor: Colors.black);
    } else if (status == "DELIVERED") {
      return statusContainer(
          text: "DELIVERED",
          bgColor: Colors.green.shade700,
          textColor: Colors.white);
    } else {
      return statusContainer(
          text: "CANCELED", bgColor: Colors.red, textColor: Colors.white);
    }
  }

  Widget statusContainer(
      {required String text, required Color bgColor, required Color textColor}) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: bgColor,
      child: Text(text, style: TextStyle(color: textColor)),
    );
  }

  Widget summaryBox(String label, int value, Color color) {
    return Container(
      height: 70,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withAlpha((0.15 * 255).round()), // replaced withOpacity
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha((0.3 * 255).round())), // replaced withOpacity
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500, color: color)),
            const SizedBox(height: 4),
            Text("$value",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Orders Dashboard",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
      ),
      body: Consumer<AdminProvider>(
        builder: (context, value, child) {
          List<OrdersModel> orders = OrdersModel.fromJsonList(value.orders);
          if (orders.isEmpty) {
            return const Center(
              child: Text("No orders found"),
            );
          }

          // Compute counts
          final int cancelledCount =
              orders.where((o) => o.status == "CANCELLED").length;
          final int onTheWayCount =
              orders.where((o) => o.status == "ON_THE_WAY").length;
          final int paidCount = orders.where((o) => o.status == "PAID").length;
          final int deliveredCount =
              orders.where((o) => o.status == "DELIVERED").length;

          return Column(
            children: [
              // Dashboard Summary
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.2,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    summaryBox("Cancelled", cancelledCount, Colors.red),
                    summaryBox("On the Way", onTheWayCount, Colors.orange),
                    summaryBox("Paid", paidCount, Colors.green),
                    summaryBox("Delivered", deliveredCount, Colors.blue),
                  ],
                ),
              ),

              Expanded(
                child: ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ViewOrder(order: order),
                            ),
                          );
                        },
                        title: Text("Order by ${order.name}"),
                        subtitle: Text(
                            "Ordered ${formatRelativeTime(order.created_at)}"),
                        trailing: statusIcon(order.status),
                        onLongPress: () {
                          showDialog(
                              context: context,
                              builder: (context) =>
                                  ModifyOrder(order: order));
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ======================= VIEW ORDER PAGE =======================
class ViewOrder extends StatelessWidget {
  final OrdersModel order;
  const ViewOrder({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Order - ${order.name}")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Customer: ${order.name}",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              Text("Phone: ${order.phone}"),
              Text("Email: ${order.email}"),
              const SizedBox(height: 20),
              Text("Status: ${order.status}"),
              Text("Ordered: ${formatRelativeTime(order.created_at)}"),
              const SizedBox(height: 20),
              const Text("Items:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Column(
                children: order.products
                    .map((item) => Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Image.network(item.image,
                          height: 50, width: 50, fit: BoxFit.cover),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(item.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500))),
                      Text(
                          "${item.quantity} x KSh${item.single_price} = KSh${item.total_price}"),
                    ],
                  ),
                ))
                    .toList(),
              ),
              const SizedBox(height: 20),
              Text("Discount: KSh${order.discount}",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              Text("Total: KSh${order.total}",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}



class ModifyOrder extends StatefulWidget {
  final OrdersModel order;
  const ModifyOrder({super.key, required this.order});

  @override
  State<ModifyOrder> createState() => _ModifyOrderState();
}

class _ModifyOrderState extends State<ModifyOrder> {
  bool _isLoading = false;

  Future<void> updateStatus(String status) async {
    setState(() => _isLoading = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await DbService.instance.updateOrderStatus(
        docId: widget.order.id,
        data: {"status": status},
      );

      if (!mounted) return;

      navigator.pop(); // close the dialog
      messenger.showSnackBar(
        SnackBar(content: Text("Order updated to $status")),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Modify Order"),
      content: _isLoading
          ? const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      )
          : Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
              onPressed: () => updateStatus("PAID"),
              child: const Text("Mark as Paid")),
          TextButton(
              onPressed: () => updateStatus("ON_THE_WAY"),
              child: const Text("Mark as Shipped")),
          TextButton(
              onPressed: () => updateStatus("DELIVERED"),
              child: const Text("Mark as Delivered")),
          TextButton(
              onPressed: () => updateStatus("CANCELLED"),
              child: const Text("Cancel Order")),
        ],
      ),
    );
  }
}
