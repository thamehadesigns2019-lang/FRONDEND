import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:thameeha/constants.dart';
import 'package:thameeha/providers/app_state.dart';
import 'package:thameeha/models/order.dart';
import 'package:thameeha/screens/order_detail_screen.dart';
import 'package:thameeha/theme/themes.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  int _limit = 20;
  int? _selectedMonth;
  int? _selectedYear;
  
  // Generate Year list (last 5 years)
  List<int> get _years {
    int currentYear = DateTime.now().year;
    return List.generate(5, (index) => currentYear - index);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchOrders();
    });
  }

  void _fetchOrders({int page = 1}) {
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.isAuthenticated) {
      appState.fetchOrders(
        page: page, 
        limit: _limit,
        month: _selectedMonth,
        year: _selectedYear
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if dark mode is active for cleaner lookups
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Consumer<AppState>(
          builder: (context, appState, child) {
            if (!appState.isAuthenticated) {
              return _buildAuthPrompt(context);
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 900) {
                  return _buildDesktopLayout(context, appState, isMobile: false);
                }
                return _buildMobileLayout(context, appState);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, AppState appState, {bool isMobile = false}) {
    final pagination = appState.ordersPagination;
    final int currentPage = pagination['current_page'] ?? 1;
    final int totalPages = pagination['total_pages'] ?? 1;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16.0 : 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, isMobile, appState),
          const SizedBox(height: 24),
          _buildFilters(context, appState),
          const SizedBox(height: 24),
          
          if (appState.orders.isEmpty)
             Expanded(child: _buildEmptyState(context))
          else
             Expanded(
               child: GridView.builder(
                 gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                   maxCrossAxisExtent: 500,
                   mainAxisExtent: 220, 
                   crossAxisSpacing: 24,
                   mainAxisSpacing: 24,
                 ),
                 itemCount: appState.orders.length,
                 itemBuilder: (context, index) {
                   return _OrderCard(
                     order: appState.orders[index], 
                     currencySymbol: appState.currencySymbol, 
                     isFixedHeight: true
                   );
                 },
               ),
             ),
          
          const SizedBox(height: 20),
          _buildPaginationControls(currentPage, totalPages),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, AppState appState) {
    final pagination = appState.ordersPagination;
    final int currentPage = pagination['current_page'] ?? 1;
    final int totalPages = pagination['total_pages'] ?? 1;

    // Use Sliver layout for better scrolling on mobile
    return CustomScrollView(
       slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            title: Text('My Orders', style: Theme.of(context).textTheme.titleLarge),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            iconTheme: Theme.of(context).iconTheme,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(72), // Increased height to prevent overflow
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: _buildFilters(context, appState),
              ),
            ),
          ),
          
          if (appState.orders.isEmpty)
            SliverFillRemaining(child: _buildEmptyState(context))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _OrderCard(
                        order: appState.orders[index], 
                        currencySymbol: appState.currencySymbol, 
                        isFixedHeight: false
                      ),
                    );
                  },
                  childCount: appState.orders.length,
                ),
              ),
            ),

          if (appState.orders.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 80), // Space for bottom bar
                child: _buildPaginationControls(currentPage, totalPages),
              ),
            )
       ],
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile, AppState appState) {
    return Row(
      children: [
        const Icon(Icons.history_edu_rounded, size: 32, color: AppTheme.primaryPurple),
        const SizedBox(width: 16),
        Text('My Orders', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildFilters(BuildContext context, AppState appState) {
    String label = "Filter by Date";
    bool isActive = false;
    if (_selectedMonth != null && _selectedYear != null) {
      label = DateFormat('MMMM yyyy').format(DateTime(_selectedYear!, _selectedMonth!));
      isActive = true;
    }

    return Row(
      children: [
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(primary: AppTheme.primaryPurple),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() {
                _selectedMonth = picked.month;
                _selectedYear = picked.year;
              });
              _fetchOrders(page: 1);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isActive ? AppTheme.primaryPurple.withOpacity(0.1) : Colors.white,
              border: Border.all(
                color: isActive ? AppTheme.primaryPurple : Colors.grey[300]!
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded, 
                  size: 20, 
                  color: isActive ? AppTheme.primaryPurple : Colors.grey[600]
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isActive ? AppTheme.primaryPurple : Colors.grey[800],
                  ),
                ),
                if (!isActive) ...[
                   const SizedBox(width: 8),
                   Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.grey[400])
                ]
              ],
            ),
          ),
        ),
        
        if (isActive) ...[
          const SizedBox(width: 12),
          IconButton(
            onPressed: () {
              setState(() {
                _selectedMonth = null;
                _selectedYear = null;
              });
              _fetchOrders(page: 1);
            },
            icon: const Icon(Icons.close_rounded),
            tooltip: "Clear Filter",
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[200],
              foregroundColor: Colors.black87,
            ),
          )
        ]
      ],
    );
  }

  Widget _buildPaginationControls(int currentPage, int totalPages) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: currentPage > 1 ? () => _fetchOrders(page: currentPage - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('Page $currentPage of $totalPages', style: Theme.of(context).textTheme.bodyMedium),
        IconButton(
          onPressed: currentPage < totalPages ? () => _fetchOrders(page: currentPage + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: Theme.of(context).disabledColor),
          const SizedBox(height: 16),
          Text(
            'No orders found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Try changing filters or go shopping!',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pushReplacementNamed('/shop'),
             style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Browse Products'),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthPrompt(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 64, color: AppTheme.primaryPurple),
          const SizedBox(height: 16),
           Text('Please Sign In', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
           Text('View your past orders and track status', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pushNamed('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final String currencySymbol;
  final bool isFixedHeight;

  const _OrderCard({
    required this.order, 
    required this.currencySymbol,
    this.isFixedHeight = false,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'processing': return Colors.blue;
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    String displayStatus = order.status;
    Color statusColor = _getStatusColor(order.status);
    final dateStr = DateFormat('MMM dd, yyyy').format(order.createdAt);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (order.paymentStatus.toLowerCase() == 'success' && 
       (order.status.toLowerCase() == 'pending' || order.status.toLowerCase() == 'processing' || order.status.toLowerCase() == 'pending payment')) {
       displayStatus = 'Success'; 
       statusColor = Colors.green;
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Order #${order.id}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        displayStatus.toUpperCase(),
                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(dateStr, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: isDark ? Colors.grey[400] : Colors.grey.shade500)),
                
                if (isFixedHeight) 
                  const Spacer()
                else 
                  const SizedBox(height: 24),

                const Divider(),
                const SizedBox(height: 8),
                  Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: Stack(
                          children: [
                            for (int i = 0; i < order.items.take(3).length; i++)
                              Positioned(
                                left: i * 30.0,
                                child: Container(
                                  width: 45,
                                  height: 45,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Theme.of(context).cardColor, width: 2),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: order.items[i].image != null && order.items[i].image!.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: order.items[i].image!,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => Container(color: Colors.grey[200]),
                                            errorWidget: (context, url, error) => Container(color: Colors.grey[200], child: const Icon(Icons.error, size: 16)),
                                          )
                                        : Container(color: Colors.grey[200], child: const Icon(Icons.image, size: 16, color: Colors.grey)),
                                  ),
                                ),
                              ),
                             if (order.items.length > 3)
                               Positioned(
                                 left: 3 * 30.0,
                                 child: Container(
                                   width: 45,
                                   height: 45,
                                   decoration: BoxDecoration(
                                     color: Colors.black87,
                                     borderRadius: BorderRadius.circular(10),
                                     border: Border.all(color: Theme.of(context).cardColor, width: 2),
                                     boxShadow: [
                                       BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                                     ],
                                   ),
                                   child: Center(
                                     child: Text(
                                       '+${order.items.length - 3}',
                                       style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                     ),
                                   ),
                                 ),
                               ),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      '$currencySymbol${order.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryPurple),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
