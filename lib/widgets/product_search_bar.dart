import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thameeha/providers/app_state.dart';
import 'package:thameeha/models/product.dart';

class ProductSearchBar extends StatefulWidget {
  final bool isMobile;
  const ProductSearchBar({super.key, this.isMobile = false});

  @override
  State<ProductSearchBar> createState() => _ProductSearchBarState();
}

class _ProductSearchBarState extends State<ProductSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<Product> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus) {
        _updateSearchQuery(_searchController.text);
      } else {
        Future.delayed(const Duration(milliseconds: 200), _removeOverlay);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _updateSearchQuery(String query) {
    if (query.isEmpty) {
      if (_filteredProducts.isNotEmpty) setState(() => _filteredProducts = []);
      _removeOverlay();
      return;
    }

    final appState = Provider.of<AppState>(context, listen: false);
    final products = appState.products;
    final lowerQuery = query.toLowerCase();

    final filtered = products.where((product) {
       final name = product.name.toLowerCase();
       final category = product.category.toLowerCase();
       final desc = product.description.toLowerCase();
       return name.contains(lowerQuery) || 
              category.contains(lowerQuery) || 
              desc.contains(lowerQuery);
    }).toList();

    // Boost advertised products to the top of the suggestions list
    filtered.sort((a, b) {
      if (a.isAdvertised && !b.isAdvertised) return -1;
      if (!a.isAdvertised && b.isAdvertised) return 1;
      return 0;
    });

    final limited = filtered.take(5).toList();

    setState(() => _filteredProducts = limited);

    if (filtered.isNotEmpty) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    final appState = Provider.of<AppState>(context, listen: false);
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
      return;
    }

    RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    var size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, size.height + 8),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.zero,
              color: Colors.white,
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _filteredProducts.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (ctx, index) {
                  final product = _filteredProducts[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                          image: product.image != null ? DecorationImage(image: NetworkImage(product.image!), fit: BoxFit.cover) : null,
                        ),
                        child: product.image == null ? const Icon(Icons.image, size: 20, color: Colors.grey) : null,
                    ),
                    title: Text(product.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text("${product.category} • ${appState.currencySymbol}${appState.getPrice(product.price)}", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    onTap: () {
                      _removeOverlay();
                      _searchController.clear();
                      _searchFocusNode.unfocus();
                      Navigator.pushNamed(context, '/shop/${product.id}');
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 1.2),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
          ]
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 20, right: 12),
              child: Icon(Icons.search, color: Colors.black87),
            ),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: const InputDecoration(
                  hintText: "Search products...",
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                  isDense: true,
                  filled: false, 
                ),
                style: const TextStyle(fontWeight: FontWeight.w500),
                onChanged: _updateSearchQuery,
                onSubmitted: (val) {
                    if (_filteredProducts.isNotEmpty) {
                      Navigator.pushNamed(context, '/shop/${_filteredProducts[0].id}');
                      _removeOverlay();
                      _searchController.clear();
                    } else if (val.isNotEmpty) {
                       Provider.of<AppState>(context, listen: false).setSelectedTab(1);
                    }
                },
              ),
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear, size: 18, color: Colors.black),
                onPressed: () {
                  _searchController.clear();
                  _updateSearchQuery('');
                  _removeOverlay();
                }
              )
            else
               const SizedBox(width: 8)
          ],
        ),
      ),
    );
  }
}
