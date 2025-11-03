
import 'package:ecommerce_admin_app/controllers/cloudinary_service.dart';
import 'package:ecommerce_admin_app/controllers/db_service.dart';
import 'package:ecommerce_admin_app/models/promo_banners_model.dart';
import 'package:ecommerce_admin_app/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ModifyPromo extends StatefulWidget {
  const ModifyPromo({super.key});

  @override
  State<ModifyPromo> createState() => _ModifyPromoState();
}

class _ModifyPromoState extends State<ModifyPromo> {
  final formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController imageController = TextEditingController();

  final ImagePicker picker = ImagePicker();
  XFile? image;

  bool _isInitialized = false;
  bool _isPromo = true;
  bool _isLoading = false;
  String productId = "";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map<String, dynamic>) {
        if (args["detail"] is PromoBannersModel) {
          setData(args["detail"] as PromoBannersModel);
        }
        _isPromo = args['promo'] ?? true;
      }
      _isInitialized = true;
      setState(() {});
    }
  }

  void setData(PromoBannersModel data) {
    productId = data.id;
    titleController.text = data.title;
    categoryController.text = data.category;
    imageController.text = data.image;
  }

  Future<void> _pickImageAndUpload() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final uploadedUrl = await uploadToCloudinary(picked);
      if (!mounted) return;

      if (uploadedUrl != null) {
        imageController.text = uploadedUrl;
        messenger.showSnackBar(
          const SnackBar(content: Text("Image uploaded successfully")),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text("Image upload failed")),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text("Upload failed: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePromo() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final data = {
      "title": titleController.text,
      "category": categoryController.text,
      "image": imageController.text,
    };

    try {
      if (productId.isNotEmpty) {
        await DbService()
            .updatePromos(id: productId, data: data, isPromo: _isPromo);
        if (!mounted) return;
        messenger.showSnackBar(SnackBar(
            content:
            Text("${_isPromo ? "Promo" : "Banner"} updated successfully")));
      } else {
        await DbService().createPromos(data: data, isPromo: _isPromo);
        if (!mounted) return;
        messenger.showSnackBar(SnackBar(
            content:
            Text("${_isPromo ? "Promo" : "Banner"} added successfully")));
      }

      if (mounted) navigator.pop();
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(
            content: Text("Failed to save ${_isPromo ? "Promo" : "Banner"}")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleText = productId.isNotEmpty
        ? _isPromo
        ? "Update Promo"
        : "Update Banner"
        : _isPromo
        ? "Add Promo"
        : "Add Banner";

    return Scaffold(
      appBar: AppBar(title: Text(titleText)),
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
                      controller: titleController,
                      validator: (v) =>
                      v!.isEmpty ? "Title cannot be empty." : null,
                      decoration: InputDecoration(
                        labelText: "Title",
                        filled: true,
                        fillColor: Colors.deepPurple.shade50,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: categoryController,
                      validator: (v) =>
                      v!.isEmpty ? "Category cannot be empty." : null,
                      readOnly: true,
                      onTap: _isLoading
                          ? null
                          : () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Select Category"),
                            content: Consumer<AdminProvider>(
                              builder: (context, value, child) =>
                                  SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: value.categories
                                          .map(
                                            (e) => TextButton(
                                          onPressed: () {
                                            categoryController.text =
                                            e["name"];
                                            Navigator.pop(context);
                                          },
                                          child: Text(e["name"]),
                                        ),
                                      )
                                          .toList(),
                                    ),
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

                    if (imageController.text.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.all(12),
                        height: 150,
                        width: double.infinity,
                        color: Colors.deepPurple.shade50,
                        child: Image.network(
                          imageController.text,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _pickImageAndUpload,
                      child: const Text("Pick Image"),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: imageController,
                      validator: (v) =>
                      v!.isEmpty ? "Image URL cannot be empty." : null,
                      decoration: InputDecoration(
                        labelText: "Image Link",
                        filled: true,
                        fillColor: Colors.deepPurple.shade50,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _savePromo,
                        child: Text(titleText),
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
