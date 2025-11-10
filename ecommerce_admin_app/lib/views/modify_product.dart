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
  String productId = "";
  final formKey = GlobalKey<FormState>();
  final ImagePicker picker = ImagePicker();
  XFile? image;

  late final TextEditingController nameController = TextEditingController();
  late final TextEditingController oldPriceController = TextEditingController();
  late final TextEditingController newPriceController = TextEditingController();
  late final TextEditingController quantityController = TextEditingController();
  late final TextEditingController categoryController = TextEditingController();
  late final TextEditingController descController = TextEditingController();
  late final TextEditingController imageController = TextEditingController();

  void setData(ProductsModel data) {
    productId = data.id;
    nameController.text = data.name;
    oldPriceController.text = data.old_price.toString();
    newPriceController.text = data.new_price.toString();
    quantityController.text = data.maxQuantity.toString();
    categoryController.text = data.category;
    descController.text = data.description;
    imageController.text = data.image;
    setState(() {});
  }

  Future<void> _pickImageAndUpload() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final uploadedUrl = await uploadToCloudinary(picked);
      if (uploadedUrl != null && mounted) {
        setState(() {
          imageController.text = uploadedUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Image uploaded successfully")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments != null && arguments is ProductsModel && productId.isEmpty) {
      setData(arguments);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(productId.isNotEmpty ? "Update Product" : "Add Product"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: nameController,
                  validator: (v) => v!.isEmpty ? "This can't be empty." : null,
                  decoration: InputDecoration(
                    hintText: "Product Name",
                    label: const Text("Product Name"),
                    fillColor: Colors.deepPurple.shade50,
                    filled: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: oldPriceController,
                  validator: (v) => v!.isEmpty ? "This can't be empty." : null,
                  decoration: InputDecoration(
                    hintText: "Original Price",
                    label: const Text("Original Price"),
                    fillColor: Colors.deepPurple.shade50,
                    filled: true,
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: newPriceController,
                  validator: (v) => v!.isEmpty ? "This can't be empty." : null,
                  decoration: InputDecoration(
                    hintText: "Sell Price",
                    label: const Text("Sell Price"),
                    fillColor: Colors.deepPurple.shade50,
                    filled: true,
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: quantityController,
                  validator: (v) => v!.isEmpty ? "This can't be empty." : null,
                  decoration: InputDecoration(
                    hintText: "Quantity Left",
                    label: const Text("Quantity Left"),
                    fillColor: Colors.deepPurple.shade50,
                    filled: true,
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: categoryController,
                  validator: (v) => v!.isEmpty ? "This can't be empty." : null,
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: "Category",
                    label: const Text("Category"),
                    fillColor: Colors.deepPurple.shade50,
                    filled: true,
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Select Category:"),
                        content: SingleChildScrollView(
                          child: Consumer<AdminProvider>(
                            builder: (context, value, child) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: value.categories.map((e) {
                                  return TextButton(
                                    onPressed: () {
                                      categoryController.text = e["name"];
                                      setState(() {});
                                      Navigator.pop(context);
                                    },
                                    child: Text(e["name"]),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: descController,
                  validator: (v) => v!.isEmpty ? "This can't be empty." : null,
                  decoration: InputDecoration(
                    hintText: "Description",
                    label: const Text("Description"),
                    fillColor: Colors.deepPurple.shade50,
                    filled: true,
                  ),
                  maxLines: 8,
                ),
                const SizedBox(height: 10),
                if (image != null)
                  Container(
                    margin: const EdgeInsets.all(20),
                    height: 200,
                    width: double.infinity,
                    color: Colors.deepPurple.shade50,
                    child: Image.file(File(image!.path), fit: BoxFit.contain),
                  )
                else if (imageController.text.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.all(20),
                    height: 100,
                    width: double.infinity,
                    color: Colors.deepPurple.shade50,
                    child: Image.network(imageController.text, fit: BoxFit.contain),
                  ),
                ElevatedButton(
                  onPressed: _pickImageAndUpload,
                  child: const Text("Pick Image"),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: imageController,
                  validator: (v) => v!.isEmpty ? "This can't be empty." : null,
                  decoration: InputDecoration(
                    hintText: "Image Link",
                    label: const Text("Image Link"),
                    fillColor: Colors.deepPurple.shade50,
                    filled: true,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;

                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);

                      Map<String, dynamic> data = {
                        "name": nameController.text,
                        "old_price": int.parse(oldPriceController.text),
                        "new_price": int.parse(newPriceController.text),
                        "quantity": int.parse(quantityController.text),
                        "category": categoryController.text,
                        "desc": descController.text,
                        "image": imageController.text,
                      };

                      if (productId.isNotEmpty) {
                        await DbService.instance.updateProduct(productId, data);
                        if (!mounted) return;
                        navigator.pop();
                        messenger.showSnackBar(
                          const SnackBar(content: Text("Product Updated")),
                        );
                      } else {
                        await DbService.instance.createProduct(data);
                        if (!mounted) return;
                        navigator.pop();
                        messenger.showSnackBar(
                          const SnackBar(content: Text("Product Added")),
                        );
                      }
                    },
                    child: Text(productId.isNotEmpty ? "Update Product" : "Add Product"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
