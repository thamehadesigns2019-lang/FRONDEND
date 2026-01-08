import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thameeha/constants.dart';
import 'package:thameeha/providers/app_state.dart';
import 'package:thameeha/models/product.dart';
import 'package:thameeha/theme/themes.dart';
import 'package:thameeha/widgets/product_card.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String _searchQuery = '';
  String _selectedCategoryName = 'All';
  String _sortBy = 'name'; // name, price_low, price_high, newest

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.selectedCategory != null) {
      setState(() {
        _selectedCategoryName = appState.selectedCategory!;
      });
      Future.microtask(() => appState.clearSelectedCategory());
    }
  }

  // Build Hierarchy
  // Returns List of Roots. Each Root has 'children' List.
  List<Map<String, dynamic>> _buildCategoryTree(List<dynamic> categories) {
    if (categories.isEmpty) return [];

    final Map<String, Map<String, dynamic>> catMap = {};
    
    // Pass 1: Map all
    for (var c in categories) {
      catMap[c['id'].toString()] = {
        ...c,
        'children': <Map<String, dynamic>>[],
      };
    }

    final List<Map<String, dynamic>> roots = [];

    // Pass 2: Link
    for (var c in categories) {
      final pid = c['parent_id']?.toString();
      final node = catMap[c['id'].toString()]!;

      if (pid != null && catMap.containsKey(pid)) {
        catMap[pid]!['children'].add(node);
      } else {
        roots.add(node);
      }
    }

    return roots;
  }

  List<Product> _getFilteredProducts(AppState appState) {
    final products = appState.products;
    final categories = appState.categories;

    // 1. Identify Target Category IDs (Selected + Children)
    Set<int> targetIds = {};
    bool isAll = _selectedCategoryName == 'All';

    if (!isAll) {
      // Find ID of selected name
      final selectedCat = categories.firstWhere(
        (c) => c['name'] == _selectedCategoryName,
        orElse: () => null,
      );

      if (selectedCat != null) {
        targetIds.add(selectedCat['id']);
        // Find descendants (supports 1 level deep for now, or use recursion)
        final pid = selectedCat['id'];
        final children = categories.where((c) => c['parent_id'] == pid).map((c) => c['id'] as int);
        targetIds.addAll(children);
      }
    }

    // 2. Filter
    var filtered = products.where((p) {
      // Search
      if (_searchQuery.isNotEmpty &&
          !p.name.toLowerCase().contains(_searchQuery) &&
          !p.description.toLowerCase().contains(_searchQuery)) {
        return false;
      }

      // Category
      if (isAll) return true;
      if (targetIds.contains(p.categoryId)) return true;
      if (p.category == _selectedCategoryName) return true; // Fallback

      return false;
    }).toList();

    // 3. Sort
    switch (_sortBy) {
      case 'price_low': filtered.sort((a, b) => a.price.compareTo(b.price)); break;
      case 'price_high': filtered.sort((a, b) => b.price.compareTo(a.price)); break;
      case 'newest': filtered.sort((a, b) => b.id.compareTo(a.id)); break;
      case 'name':
      default: filtered.sort((a, b) => a.name.compareTo(b.name)); break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], 
      body: _buildLayout(context),
    );
  }

  Widget _buildLayout(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 800;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          width: double.infinity,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isDesktop ? 600 : double.infinity), 
              child: Column(
                children: [
                   _buildSearchBar(),
                   const SizedBox(height: 16),
                   
                   // Enhanced Mobile Filter Bar
                   Row(
                     children: [
                       // Category Filter - Expanded
                       Expanded(
                         child: Consumer<AppState>(
                           builder: (context, appState, _) {
                             final roots = _buildCategoryTree(appState.categories);
                             return PopupMenuButton<String>(
                               offset: const Offset(0, 50),
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                               elevation: 4,
                               child: Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                 decoration: BoxDecoration(
                                   color: Colors.white,
                                   border: Border.all(color: Colors.black, width: 1.2),
                                   borderRadius: BorderRadius.circular(16),
                                   boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                                   ]
                                 ),
                                 child: Row(
                                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                   children: [
                                     Expanded(
                                       child: Row(
                                         children: [
                                           Icon(Icons.grid_view_rounded, color: Colors.grey[700], size: 20),
                                           const SizedBox(width: 8),
                                           Expanded(
                                             child: Text(
                                               _selectedCategoryName == 'All' ? 'Category' : _selectedCategoryName, 
                                               style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                               maxLines: 1,
                                               overflow: TextOverflow.ellipsis,
                                             ),
                                           ),
                                         ],
                                       ),
                                     ),
                                     const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                                   ],
                                 ),
                               ),
                               onSelected: (v) => setState(() => _selectedCategoryName = v),
                               itemBuilder: (context) {
                                 List<PopupMenuEntry<String>> items = [
                                   const PopupMenuItem(value: 'All', textStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.black), child: Text('All Products')),
                                   const PopupMenuDivider(),
                                 ];
                                 
                                 for (var root in roots) {
                                   items.add(PopupMenuItem(
                                     value: root['name'],
                                     child: Text(root['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                                   ));
                                   if (root['children'] != null) {
                                     for (var child in root['children']) {
                                       items.add(PopupMenuItem(
                                         value: child['name'],
                                         height: 32, // More compact children
                                         child: Row(
                                           children: [
                                             const SizedBox(width: 12),
                                             Icon(Icons.subdirectory_arrow_right, size: 16, color: Colors.grey[400]),
                                             const SizedBox(width: 8),
                                             Text(child['name'], style: TextStyle(color: Colors.grey[800], fontSize: 13)),
                                           ],
                                         ),
                                       ));
                                     }
                                   }
                                 }
                                 return items;
                               },
                             );
                           }
                         ),
                       ),
                       
                       const SizedBox(width: 12),
                       
                       // Sort Dropdown
                       Expanded(
                         child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                               // Show sort modal
                                showModalBottomSheet(
                                  context: context,
                                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                  builder: (context) => Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                       const SizedBox(height: 12),
                                       Container(height: 4, width: 40, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                                       const Padding(
                                         padding: EdgeInsets.all(16.0),
                                         child: Text("Sort By", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                       ),
                                       ...[
                                          {'id': 'name', 'label': 'Name'},
                                          {'id': 'price_low', 'label': 'Price: Low to High'},
                                          {'id': 'price_high', 'label': 'Price: High to Low'},
                                          {'id': 'newest', 'label': 'Newest'},
                                       ].map((s) => ListTile(
                                          title: Text(s['label']!),
                                          trailing: _sortBy == s['id'] ? const Icon(Icons.check, color: AppTheme.primaryPurple) : null,
                                          onTap: () {
                                             setState(() => _sortBy = s['id']!);
                                             Navigator.pop(context);
                                          },
                                       )),
                                       const SizedBox(height: 24),
                                    ],
                                  )
                                );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                     color: Colors.white,
                                     border: Border.all(color: Colors.black, width: 1.2),
                                     borderRadius: BorderRadius.circular(16),
                                     boxShadow: [
                                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                                     ]
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.sort_rounded, color: Colors.grey[700], size: 20),
                                      const SizedBox(width: 8),
                                      const Text("Sort By", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    ],
                                  ),
                                  const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                                ],
                              ),
                            ),
                         ),
                       ),
                     ],
                   ),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: _buildProductGrid()),
      ],
    );
  }

  Widget _buildCategoryNode(Map<String, dynamic> node) {
    final children = node['children'] as List;
    final name = node['name'] as String;
    
    // If no children, simple tile
    if (children.isEmpty) {
      return _buildCategoryTile(
        title: name, 
        isSelected: _selectedCategoryName == name, 
        onTap: () => setState(() => _selectedCategoryName = name)
      );
    }

    // Interactive Parent? 
    // Usually clicking Parent shows parent's items (and subs items)
    // AND toggles expansion? 
    // ExpansionTile does toggle on tap.
    // I'll add a separate tap area or just use ExpansionTile logic.
    // If I check "is selected", I expand it?
    
    // Simplification: ExpansionTile title IS clickable to Select? 
    // No, ExpansionTile header click Toggles.
    // I'll put a Radio/Check or similar? 
    // Or just let user select Children. 
    // But user wants "Category" (Root).
    // I'll make the Title a Row.
    
    return ExpansionTile(
      title: InkWell(
        onTap: () {
           setState(() => _selectedCategoryName = name);
        },
        child: Text(
          name, 
          style: TextStyle(
            fontWeight: _selectedCategoryName == name ? FontWeight.bold : FontWeight.w500,
            color: _selectedCategoryName == name ? AppTheme.primaryPurple : Colors.black87
          )
        ),
      ),
      initiallyExpanded: _selectedCategoryName == name || children.any((c) => c['name'] == _selectedCategoryName),
      textColor: AppTheme.primaryPurple,
      iconColor: AppTheme.primaryPurple,
      shape: const Border(),
      childrenPadding: const EdgeInsets.only(left: 16),
      children: children.map((c) => _buildCategoryNode(c)).toList(), // Recursion support
    );
  }

  Widget _buildCategoryTile({required String title, required bool isSelected, required VoidCallback onTap}) {
    return ListTile(
      title: Text(title, style: TextStyle(
         color: isSelected ? AppTheme.primaryPurple : Colors.black87,
         fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      )),
      selected: isSelected,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      tileColor: isSelected ? AppTheme.primaryPurple.withOpacity(0.05) : null,
      onTap: onTap,
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
        style: const TextStyle(fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'Search products...',
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 20, right: 12),
            child: Icon(Icons.search, color: Colors.black87),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: const BorderSide(color: Colors.black, width: 1.2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: const BorderSide(color: Colors.black, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: const BorderSide(color: Colors.black, width: 2.0),
          ),
        ),
      ),
    );
  }

  Widget _buildSortDropdown({bool isExpanded = false}) {
       return Container(
         padding: const EdgeInsets.symmetric(horizontal: 16),
         decoration: BoxDecoration(
           color: Colors.white, 
           borderRadius: BorderRadius.circular(12),
           border: Border.all(color: Colors.grey.shade300),
         ),
         child: DropdownButtonHideUnderline(
           child: DropdownButton<String>(
             value: _sortBy,
             isExpanded: isExpanded,
             icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
             style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 14),
             items: const [
               DropdownMenuItem(value: 'name', child: Text('Name')),
               DropdownMenuItem(value: 'price_low', child: Text('Price: Low to High')),
               DropdownMenuItem(value: 'price_high', child: Text('Price: High to Low')),
               DropdownMenuItem(value: 'newest', child: Text('Newest')),
             ],
             onChanged: (v) => setState(() => _sortBy = v!),
           ),
         ),
       );
  }

  Widget _buildProductGrid() {
    return Consumer<AppState>(
      builder: (context, appState, _) {
         final filtered = _getFilteredProducts(appState);
         
         if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.search_off, size: 64, color: Colors.grey),
                   const SizedBox(height: 16),
                   Text('No products found', style: TextStyle(color: Colors.grey[600], fontSize: 18))
                ],
              ),
            );
         }

         return LayoutBuilder(
           builder: (context, constraints) {
              int crossAxisCount = 2;
              double padding = 16;
              if (constraints.maxWidth > 1600) { crossAxisCount = 6; padding = 32; }
              else if (constraints.maxWidth > 1300) { crossAxisCount = 5; padding = 32; }
              else if (constraints.maxWidth > 1000) { crossAxisCount = 4; padding = 24; }
              else if (constraints.maxWidth > 600) { crossAxisCount = 3; padding = 24; }
              
              return GridView.builder(
                padding: EdgeInsets.all(padding),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                   crossAxisCount: crossAxisCount,
                   crossAxisSpacing: 16,
                   mainAxisSpacing: 16,
                   childAspectRatio: 0.7,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) => ProductCard(product: filtered[index]),
              );
           }
         );
      }
    );
  }
}
