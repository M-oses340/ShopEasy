import 'dart:io';
import 'package:ecommerce_admin_app/controllers/cloudinary_service.dart';
import 'package:ecommerce_admin_app/controllers/db_service.dart';
import 'package:ecommerce_admin_app/models/products_model.dart';
import 'package:ecommerce_admin_app/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ModifyProduct extends StatefulWidget {
  const ModifyProduct({super.key});

  @override
  State<ModifyProduct> createState() => _ModifyProductState();
}

class _ModifyProductState extends State<ModifyProduct> {
  late String productId = "";
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final oldPriceController = TextEditingController();
  final newPriceController = TextEditingController();
  final quantityController = TextEditingController();
  final categoryController = TextEditingController();
  final descController = TextEditingController();
  final imageController = TextEditingController();

  final ImagePicker picker = ImagePicker();
  XFile? image;
  bool _isLoading = false;
  bool _isInitialized = false;

  void setData(ProductsModel data) {
    productId = data.id;
    nameController.text = data.name;
    oldPriceController.text = data.old_price.toString();
    newPriceController.text = data.new_price.toString();
    quantityController.text = data.maxQuantity.toString();
    categoryController.text = data.category;
    descController.text = data.description;
    imageController.text = data.image;
  }

  Future<void> _pickImageAndCloudinaryUpload() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _isLoading = true);

    final messenger = ScaffoldMessenger.of(context);

    try {
      final uploadedUrl = await uploadToCloudinary(picked);
      if (uploadedUrl != null) {
        setState(() => imageController.text = uploadedUrl);
        messenger.showSnackBar(
          const SnackBar(content: Text("Image uploaded successfully")),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text("Image upload failed")),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProduct() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final data = {
      "name": nameController.text,
      "old_price": int.parse(oldPriceController.text),
      "new_price": int.parse(newPriceController.text),
      "quantity": int.parse(quantityController.text),
      "category": categoryController.text,
      "desc": descController.text,
      "image": imageController.text,
    };

    try {
      if (productId.isNotEmpty) {
        await DbService.instance.updateProduct(productId, data);
        messenger.showSnackBar(
          const SnackBar(content: Text("Product Updated")),
        );
      } else {
        await DbService.instance.createProduct(data);
        messenger.showSnackBar(
          const SnackBar(content: Text("Product Added")),
        );
      }
      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text("Failed to save product: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (!_isInitialized && args != null && args is ProductsModel) {
      setData(args);
      _isInitialized = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(productId.isNotEmpty ? "Update Product" : "Add Product"),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(8.0),
            child: AbsorbPointer(
              absorbing: _isLoading,
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameController,
                      validator: (v) =>
                      v!.isEmpty ? "This cant be empty." : null,
                      decoration: InputDecoration(
                        labelText: "Product Name",
                        filled: true,
                        fillColor: Colors.deepPurple.shade50,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: oldPriceController,
                      validator: (v) =>
                      v!.isEmpty ? "This cant be empty." : null,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Original Price",
                        filled: true,
                        fillColor: Colors.deepPurple.shade50,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: newPriceController,
                      validator: (v) =>
                      v!.isEmpty ? "This cant be empty." : null,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Sell Price",
                        filled: true,
                        fillColor: Colors.deepPurple.shade50,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: quantityController,
                      validator: (v) =>
                      v!.isEmpty ? "This cant be empty." : null,
                      decoration: InputDecoration(
                        labelText: "Quantity Left",
                        filled: true,
                        fillColor: Colors.deepPurple.shade50,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: categoryController,
                      readOnly: true,
                      validator: (v) =>
                      v!.isEmpty ? "This cant be empty." : null,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Select Category"),
                            content: Consumer<AdminProvider>(
                              builder: (context, value, child) => Column(
                                mainAxisSize: MainAxisSize.min,
                                children: value.categories
                                    .map(
                                      (e) => TextButton(
                                    onPressed: () {
                                      categoryController.text = e["name"];
                                      Navigator.pop(context);
                                    },
                                    child: Text(e["name"]),
                                  ),
                                )
                                    .toList(),
                              ),
                            ),
                          ),
                        );
                      },
                      decoration: InputDecoration(
                        labelText: "Category",
                        filled: true,
                        fillColor: Colors.deepPurple.shade50,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: descController,
                      validator: (v) =>
                      v!.isEmpty ? "This cant be empty." : null,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: "Description",
                        filled: true,
                        fillColor: Colors.deepPurple.shade50,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (imageController.text.isNotEmpty || image != null)
                      Container(
                        margin: const EdgeInsets.all(12),
                        height: 150,
                        width: double.infinity,
                        color: Colors.deepPurple.shade50,
                        child: image != null
                            ? Image.file(File(image!.path), fit: BoxFit.contain)
                            : Image.network(imageController.text,
                            fit: BoxFit.contain),
                      ),
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : _pickImageAndCloudinaryUpload,
                      child: const Text("Pick Image"),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProduct,
                        child: Text(
                            productId.isNotEmpty ? "Update Product" : "Add Product"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
