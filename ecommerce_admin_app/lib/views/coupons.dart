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
    final db = DbService.instance; // Use singleton

    return Scaffold(
      appBar: AppBar(title: const Text("Coupons")),
      body: Stack(
        children: [
          StreamBuilder(
            stream: db.readCoupons(),
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
                    title: Text(coupon.code),
                    subtitle: Text(coupon.desc),
                    onTap: _isLoading
                        ? null
                        : () => _showAddOrUpdateCoupon(context, coupon),
                    onLongPress: _isLoading
                        ? null
                        : () => _showDeleteConfirm(context, coupon),
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
        onPressed: _isLoading ? null : () => _showAddOrUpdateCoupon(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, CouponModel coupon) {
    showDialog(
      context: context,
      builder: (ctx) => AdditionalConfirm(
        contentText: "Are you sure you want to delete this coupon?",
        onYes: () async {
          setState(() => _isLoading = true);
          final messenger = ScaffoldMessenger.of(context);
          try {
            await DbService.instance.deleteCoupon(coupon.id);
            messenger.showSnackBar(const SnackBar(content: Text("Coupon deleted successfully.")));
          } catch (e) {
            messenger.showSnackBar(SnackBar(content: Text("Error deleting coupon: $e")));
          } finally {
            if (mounted) setState(() => _isLoading = false);
            if (mounted) Navigator.pop(ctx);
          }
        },
        onNo: () => Navigator.pop(ctx),
      ),
    );
  }

  void _showAddOrUpdateCoupon(BuildContext context, CouponModel? coupon) {
    showDialog(
      context: context,
      builder: (_) => ModifyCoupon(
        id: coupon?.id ?? "",
        code: coupon?.code ?? "",
        desc: coupon?.desc ?? "",
        discount: coupon?.discount ?? 0,
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
              _buildTextField(controller: codeController, label: "Coupon Code"),
              const SizedBox(height: 10),
              _buildTextField(controller: descController, label: "Description"),
              const SizedBox(height: 10),
              TextFormField(
                controller: discountController,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return "This can't be empty.";
                  final value = int.tryParse(v);
                  if (value == null) return "Enter a valid number.";
                  if (value < 1 || value > 100) return "Discount must be 1-100%";
                  return null;
                },
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
          onPressed: _isSubmitting ? null : _submit,
          child: Text(widget.id.isNotEmpty ? "Update" : "Add"),
        ),
      ],
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label}) {
    return TextFormField(
      controller: controller,
      validator: (v) => v == null || v.isEmpty ? "This can't be empty." : null,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.deepPurple.shade50,
      ),
    );
  }

  Future<void> _submit() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);

    final data = {
      "code": codeController.text.trim().toUpperCase(),
      "desc": descController.text.trim(),
      "discount": int.parse(discountController.text.trim()),
    };

    try {
      if (widget.id.isNotEmpty) {
        await DbService.instance.updateCoupon(widget.id, data);
        messenger.showSnackBar(const SnackBar(content: Text("Coupon updated successfully.")));
      } else {
        await DbService.instance.createCoupon(data);
        messenger.showSnackBar(const SnackBar(content: Text("Coupon added successfully.")));
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
