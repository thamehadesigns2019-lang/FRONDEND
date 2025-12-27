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
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return _buildDesktopLayout(context);
          }
          return _buildMobileLayout(context);
        },
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sidebar
        Container(
          width: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('Filters', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _buildSearchBar(),
              ),
              const SizedBox(height: 24),
              const Padding(
                 padding: EdgeInsets.symmetric(horizontal: 24.0),
                 child: Text('Categories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Consumer<AppState>(
                  builder: (context, appState, _) {
                    final roots = _buildCategoryTree(appState.categories);
                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildCategoryTile( title: 'All', isSelected: _selectedCategoryName == 'All', onTap: () => setState(() => _selectedCategoryName = 'All')),
                        ...roots.map((node) => _buildCategoryNode(node)).toList(),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        
        // Grid
        Expanded(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Text(
                       _selectedCategoryName, 
                       style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primaryPurple)
                     ),
                     SizedBox(width: 200, child: _buildSortDropdown(isExpanded: true)),
                  ],
                ),
              ),
              Expanded(child: _buildProductGrid()),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
               _buildSearchBar(),
               const SizedBox(height: 12),
                Row(
                  children: [
                    // Category Filter Icon Button
                    Flexible(
                      flex: 2,
                      child: Consumer<AppState>(
                        builder: (context, appState, _) {
                          final roots = _buildCategoryTree(appState.categories);
                          
                          return PopupMenuButton<String>(
                            tooltip: 'Filter by Category',
                            child: Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.filter_alt, color: AppTheme.primaryPurple, size: 20),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      _selectedCategoryName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                ],
                              ),
                            ),
                            onSelected: (v) => setState(() => _selectedCategoryName = v),
                            itemBuilder: (context) {
                              List<PopupMenuEntry<String>> items = [
                                const PopupMenuItem(value: 'All', child: Text('All Products')),
                              ];
                              
                              for (var root in roots) {
                                items.add(PopupMenuItem(
                                  value: root['name'],
                                  child: Text(root['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                ));
                                if (root['children'] != null) {
                                  for (var child in root['children']) {
                                    items.add(PopupMenuItem(
                                      value: child['name'],
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 16.0),
                                        child: Text(child['name']),
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
                    // Sort Dropdown (More compact)
                    Flexible(
                      flex: 1,
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100], 
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _buildSortDropdown(isExpanded: true),
                      ),
                    ),
                  ],
                ),
            ],
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
    return TextField(
      onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
      decoration: InputDecoration(
        hintText: 'Search products...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildSortDropdown({bool isExpanded = false}) {
     return Container(
       padding: const EdgeInsets.symmetric(horizontal: 12),
       decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
       child: DropdownButtonHideUnderline(
         child: DropdownButton<String>(
           value: _sortBy,
           isExpanded: isExpanded,
           icon: const Icon(Icons.sort),
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
              if (constraints.maxWidth > 1200) { crossAxisCount = 4; padding = 32; }
              else if (constraints.maxWidth > 800) { crossAxisCount = 3; padding = 24; }
              
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
