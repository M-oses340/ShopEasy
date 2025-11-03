import 'package:ecommerce_admin_app/containers/additional_confirm.dart';
import 'package:ecommerce_admin_app/controllers/db_service.dart';
import 'package:ecommerce_admin_app/models/products_model.dart';
import 'package:ecommerce_admin_app/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  bool _isLoading = false;

  void _showProductActions(BuildContext context, ProductsModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Choose what you want"),
        content: const Text("Deleting cannot be undone."),
        actions: [
          // ✅ DELETE BUTTON
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => AdditionalConfirm(
                  contentText:
                  "Are you sure you want to delete this product?",
                  onYes: () async {
                    setState(() => _isLoading = true);

                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);

                    try {
                      await DbService()
                          .deleteProduct(docId: product.id);

                      if (!mounted) return;
                      setState(() => _isLoading = false);

                      navigator.pop(); // Close confirmation dialog

                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text("Product deleted successfully."),
                        ),
                      );
                    } catch (e) {
                      if (mounted) {
                        setState(() => _isLoading = false);
                        messenger.showSnackBar(
                          SnackBar(
                              content: Text(
                                  "Failed to delete product: $e")),
                        );
                      }
                    }
                  },
                  onNo: () => Navigator.pop(context),
                ),
              );
            },
            child: const Text("Delete Product"),
          ),

          // ✅ EDIT BUTTON
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                "/add_product",
                arguments: product,
              );
            },
            child: const Text("Edit Product"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Products")),
      body: Stack(
        children: [
          Consumer<AdminProvider>(
            builder: (context, value, child) {
              final products =
              ProductsModel.fromJsonList(value.products);

              if (products.isEmpty) {
                return const Center(child: Text("No Products Found"));
              }

              return ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];

                  return ListTile(
                    onLongPress: () => _showProductActions(context, product),
                    onTap: () => Navigator.pushNamed(
                      context,
                      "/view_product",
                      arguments: product,
                    ),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        product.image,
                        height: 50,
                        width: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image),
                      ),
                    ),
                    title: Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("KSh ${product.new_price.toString()}"),
                        Container(
                          padding: const EdgeInsets.all(4),
                          color: Theme.of(context).primaryColor,
                          child: Text(
                            product.category.toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: _isLoading
                          ? null
                          : () {
                        Navigator.pushNamed(
                          context,
                          "/add_product",
                          arguments: product,
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),

          // ✅ LOADING OVERLAY
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
          Navigator.pushNamed(context, "/add_product");
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
