
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

  void _showAnimatedDialog(Widget dialog) {
    showGeneralDialog(
      context: context,
      barrierLabel: "Dialog",
      barrierDismissible: true,
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) => Center(child: dialog),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
    );
  }

  void _showActionDialog(PromoBannersModel promo) {
    final theme = Theme.of(context);
    _showAnimatedDialog(AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      title: Text(
        "Choose Action",
        style: theme.textTheme.titleMedium,
      ),
      content: Text(
        "Deleting cannot be undone.",
        style: theme.textTheme.bodyMedium,
      ),
      actions: [
        // DELETE BUTTON
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
            Navigator.pop(context);
            _showAnimatedDialog(AdditionalConfirm(
              contentText: "Are you sure you want to delete this item?",
              onYes: () async {
                setState(() => _isLoading = true);
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);

                try {
                  await DbService.instance.deletePromo(_isPromo, promo.id);
                  if (!mounted) return;

                  setState(() => _isLoading = false);
                  navigator.pop();

                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        "${_isPromo ? "Promo" : "Banner"} deleted successfully",
                      ),
                      backgroundColor: theme.colorScheme.error,
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
            ));
          },
          child: Text(
            "Delete ${_isPromo ? "Promo" : "Banner"}",
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),

        // UPDATE BUTTON
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
            Navigator.pop(context);
            Navigator.pushNamed(
              context,
              "/update_promo",
              arguments: {"promo": _isPromo, "detail": promo},
            );
          },
          child: Text(
            "Update ${_isPromo ? "Promo" : "Banner"}",
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_isInitialized) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isPromo ? "Promos" : "Banners"),
      ),
      body: Stack(
        children: [
          StreamBuilder(
            stream: DbService.instance.readPromos(_isPromo),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: theme.colorScheme.primary),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "Error loading ${_isPromo ? "promos" : "banners"}",
                    style: theme.textTheme.bodyLarge,
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    "No ${_isPromo ? "Promos" : "Banners"} found",
                    style: theme.textTheme.bodyLarge,
                  ),
                );
              }

              final promos = PromoBannersModel.fromJsonList(snapshot.data!.docs);

              return LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 1;
                  double width = constraints.maxWidth;

                  if (width > 1200) {
                    crossAxisCount = 4;
                  } else if (width > 900) {
                    crossAxisCount = 3;
                  } else if (width > 600) {
                    crossAxisCount = 2;
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 3.5,
                    ),
                    itemCount: promos.length,
                    itemBuilder: (context, index) {
                      final promo = promos[index];
                      return InkWell(
                        onTap: () => _showActionDialog(promo),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: theme.shadowColor.withValues(alpha: 25),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  promo.image,
                                  height: 60,
                                  width: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.broken_image,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      promo.title,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      promo.category,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit_outlined,
                                    color: theme.colorScheme.primary),
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                  Navigator.pushNamed(
                                    context,
                                    "/update_promo",
                                    arguments: {"promo": _isPromo, "detail": promo},
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
          if (_isLoading)
            Container(
              color: theme.colorScheme.surface.withValues(alpha: 75),
              child: Center(
                child: CircularProgressIndicator(color: theme.colorScheme.primary),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading
            ? null
            : () {
          Navigator.pushNamed(context, "/update_promo", arguments: {"promo": _isPromo});
        },
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
