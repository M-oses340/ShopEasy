import 'package:ecommerce_admin_app/containers/additional_confirm.dart';
import 'package:ecommerce_admin_app/controllers/db_service.dart';
import 'package:ecommerce_admin_app/models/promo_banners_model.dart';
import 'package:flutter/material.dart';

class PromoBannersPage extends StatefulWidget {
  const PromoBannersPage({super.key});

  @override
  State<PromoBannersPage> createState() => _PromoBannersPageState();
}

class _PromoBannersPageState extends State<PromoBannersPage> {
  bool _isInitialized = false;
  bool _isPromo = true;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments != null && arguments is Map<String, dynamic>) {
        _isPromo = arguments['promo'] ?? true;
      }
      _isInitialized = true;
      setState(() {});
    }
  }

  void _showActionDialog(PromoBannersModel promo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("What do you want to do?"),
        content: const Text("Deleting cannot be undone."),
        actions: [
          // ✅ DELETE BUTTON
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
              Navigator.pop(context); // Close main action dialog
              showDialog(
                context: context,
                builder: (context) => AdditionalConfirm(
                  contentText: "Are you sure you want to delete this item?",
                  onYes: () async {
                    setState(() => _isLoading = true);

                    // Capture these before await to avoid context issues
                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);

                    try {
                      await DbService.instance.deletePromo(_isPromo, promo.id);


                      if (!mounted) return;

                      setState(() => _isLoading = false);
                      navigator.pop(); // Close confirmation dialog

                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            "${_isPromo ? "Promo" : "Banner"} deleted successfully.",
                          ),
                        ),
                      );
                    } catch (e) {
                      if (mounted) {
                        setState(() => _isLoading = false);
                        messenger.showSnackBar(
                          SnackBar(content: Text("Error: $e")),
                        );
                      }
                    }
                  },
                  onNo: () => Navigator.pop(context),
                ),
              );
            },
            child: Text("Delete ${_isPromo ? "Promo" : "Banner"}"),
          ),

          // ✅ UPDATE BUTTON
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                "/update_promo",
                arguments: {
                  "promo": _isPromo,
                  "detail": promo,
                },
              );
            },
            child: Text("Update ${_isPromo ? "Promo" : "Banner"}"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isPromo ? "Promos" : "Banners"),
      ),
      body: Stack(
        children: [
          StreamBuilder(
            stream: DbService.instance
                .readPromos(_isPromo),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text("Error loading ${_isPromo ? "promos" : "banners"}"),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text("No ${_isPromo ? "Promos" : "Banners"} found"),
                );
              }

              final promos = PromoBannersModel.fromJsonList(snapshot.data!.docs);

              return ListView.builder(
                itemCount: promos.length,
                itemBuilder: (context, index) {
                  final promo = promos[index];
                  return ListTile(
                    onTap: () => _showActionDialog(promo),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        promo.image,
                        height: 50,
                        width: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image),
                      ),
                    ),
                    title: Text(
                      promo.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(promo.category),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: _isLoading
                          ? null
                          : () {
                        Navigator.pushNamed(
                          context,
                          "/update_promo",
                          arguments: {
                            "promo": _isPromo,
                            "detail": promo,
                          },
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
          Navigator.pushNamed(
            context,
            "/update_promo",
            arguments: {"promo": _isPromo},
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
