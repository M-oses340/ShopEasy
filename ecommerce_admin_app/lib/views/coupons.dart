import 'package:ecommerce_admin_app/containers/additional_confirm.dart';
import 'package:ecommerce_admin_app/controllers/db_service.dart';
import 'package:ecommerce_admin_app/models/coupon_model.dart';
import 'package:flutter/material.dart';

class CouponsPage extends StatefulWidget {
  const CouponsPage({super.key});

  @override
  State<CouponsPage> createState() => _CouponsPageState();
}

class _CouponsPageState extends State<CouponsPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Coupons")),
      body: Stack(
        children: [
          StreamBuilder(
            stream: DbService().readCouponCode(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(child: Text("Error loading coupons"));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No coupons found"));
              }

              final coupons = CouponModel.fromJsonList(snapshot.data!.docs);

              return ListView.builder(
                itemCount: coupons.length,
                itemBuilder: (context, index) {
                  final coupon = coupons[index];

                  return ListTile(
                    onTap: _isLoading
                        ? null
                        : () {
                      _showActionDialog(context, coupon);
                    },
                    title: Text(coupon.code),
                    subtitle: Text(coupon.desc),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: _isLoading
                          ? null
                          : () {
                        showDialog(
                          context: context,
                          builder: (context) => ModifyCoupon(
                            id: coupon.id,
                            code: coupon.code,
                            desc: coupon.desc,
                            discount: coupon.discount,
                          ),
                        );
                      },
                    ),
                  );
                },
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
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading
            ? null
            : () {
          showDialog(
            context: context,
            builder: (context) => const ModifyCoupon(
              id: "",
              code: "",
              desc: "",
              discount: 0,
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showActionDialog(BuildContext context, CouponModel coupon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("What would you like to do?"),
        content: const Text("Deleting cannot be undone."),
        actions: [
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => AdditionalConfirm(
                  contentText: "Are you sure you want to delete this coupon?",
                  onYes: () async {
                    setState(() => _isLoading = true);
                    final messenger = ScaffoldMessenger.of(context);

                    try {
                      await DbService().deleteCouponCode(docId: coupon.id);
                      if (mounted) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text("Coupon deleted successfully.")),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(content: Text("Error deleting coupon: $e")),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                      if (mounted) Navigator.pop(context);
                    }
                  },
                  onNo: () => Navigator.pop(context),
                ),
              );
            },
            child: const Text("Delete Coupon"),
          ),
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => ModifyCoupon(
                  id: coupon.id,
                  code: coupon.code,
                  desc: coupon.desc,
                  discount: coupon.discount,
                ),
              );
            },
            child: const Text("Update Coupon"),
          ),
        ],
      ),
    );
  }
}

class ModifyCoupon extends StatefulWidget {
  final String id, code, desc;
  final int discount;

  const ModifyCoupon({
    super.key,
    required this.id,
    required this.code,
    required this.desc,
    required this.discount,
  });

  @override
  State<ModifyCoupon> createState() => _ModifyCouponState();
}

class _ModifyCouponState extends State<ModifyCoupon> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController codeController;
  late final TextEditingController descController;
  late final TextEditingController discountController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    codeController = TextEditingController(text: widget.code);
    descController = TextEditingController(text: widget.desc);
    discountController = TextEditingController(text: widget.discount.toString());
  }

  @override
  void dispose() {
    codeController.dispose();
    descController.dispose();
    discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.id.isNotEmpty ? "Update Coupon" : "Add Coupon"),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("All coupon codes will be converted to uppercase"),
              const SizedBox(height: 10),
              TextFormField(
                controller: codeController,
                validator: (v) => v!.isEmpty ? "This can't be empty." : null,
                decoration: InputDecoration(
                  labelText: "Coupon Code",
                  filled: true,
                  fillColor: Colors.deepPurple.shade50,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: descController,
                validator: (v) => v!.isEmpty ? "This can't be empty." : null,
                decoration: InputDecoration(
                  labelText: "Description",
                  filled: true,
                  fillColor: Colors.deepPurple.shade50,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: discountController,
                validator: (v) => v!.isEmpty ? "This can't be empty." : null,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Discount (%)",
                  filled: true,
                  fillColor: Colors.deepPurple.shade50,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _isSubmitting
              ? null
              : () async {
            if (formKey.currentState!.validate()) {
              setState(() => _isSubmitting = true);
              final messenger = ScaffoldMessenger.of(context);

              final data = {
                "code": codeController.text.trim().toUpperCase(),
                "desc": descController.text.trim(),
                "discount": int.tryParse(discountController.text.trim()) ?? 0,
              };

              try {
                if (widget.id.isNotEmpty) {
                  await DbService().updateCouponCode(docId: widget.id, data: data);
                  messenger.showSnackBar(
                    const SnackBar(content: Text("Coupon updated successfully.")),
                  );
                } else {
                  await DbService().createCouponCode(data: data);
                  messenger.showSnackBar(
                    const SnackBar(content: Text("Coupon added successfully.")),
                  );
                }
                if (mounted) Navigator.pop(context);
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text("Error: $e")));
              } finally {
                if (mounted) setState(() => _isSubmitting = false);
              }
            }
          },
          child: Text(widget.id.isNotEmpty ? "Update" : "Add"),
        ),
      ],
    );
  }
}
