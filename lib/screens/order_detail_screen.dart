import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:thameeha/constants.dart';
import 'package:thameeha/providers/app_state.dart';
import 'package:thameeha/models/order.dart';
import 'package:thameeha/models/order_item.dart';
import 'package:thameeha/theme/themes.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Order? _order;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final order = await appState.apiService.fetchOrderDetail(widget.orderId);
      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load order details: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_errorMessage != null) return Scaffold(body: Center(child: Text(_errorMessage!)));
    if (_order == null) return const Scaffold(body: Center(child: Text('Order not found.')));

    final currency = Provider.of<AppState>(context).currencySymbol;

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light bg
      appBar: AppBar(
        title: Text('Order #${_order!.id}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return _buildDesktopLayout(context, _order!, currency);
          }
          return _buildMobileLayout(context, _order!, currency);
        },
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, Order order, String currency) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        padding: const EdgeInsets.all(40),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Items and Timeline
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusTimeline(order),
                  const SizedBox(height: 24),
                  _buildItemsCard(order, currency),
                ],
              ),
            ),
            const SizedBox(width: 40),
            // Right Column: Summary and Address
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  _buildSummaryCard(order, currency),
                  const SizedBox(height: 24),
                  _buildAddressCard(order),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, Order order, String currency) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatusTimeline(order),
          const SizedBox(height: 16),
          _buildItemsCard(order, currency),
          const SizedBox(height: 16),
          _buildSummaryCard(order, currency),
          const SizedBox(height: 16),
          _buildAddressCard(order),
        ],
      ),
    );
  }

  Widget _buildItemsCard(Order order, String currency) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Items', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: order.items.length,
            separatorBuilder: (context, index) => const Divider(height: 32),
            itemBuilder: (context, index) {
              final item = order.items[index];
              return Row(
                children: [
                   Container(
                     width: 80,
                     height: 80,
                     decoration: BoxDecoration(
                       color: Colors.grey[100],
                       borderRadius: BorderRadius.circular(8),
                     ),
                     child: ClipRRect(
                       borderRadius: BorderRadius.circular(8),
                        child: item.image != null && item.image!.isNotEmpty
                          ? CachedNetworkImage(
                               imageUrl: item.image!, 
                               fit: BoxFit.cover,
                               placeholder: (context, url) => Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey[300])),
                               errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                             )
                          : const Icon(Icons.image_not_supported, color: Colors.grey),
                     )
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                         const SizedBox(height: 4),
                         if (item.selectedOptions != null && item.selectedOptions!.isNotEmpty)
                           Padding(
                             padding: const EdgeInsets.only(bottom: 4.0),
                             child: Wrap(
                               spacing: 8,
                               children: item.selectedOptions!.entries.map((e) {
                                 return Container(
                                   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                   decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                                   child: Text('${e.key}: ${e.value}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                                 );
                               }).toList(),
                             ),
                           ),
                         Text('Qty: ${item.quantity}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                       ],
                     ),
                   ),
                   Text(
                     '$currency${(item.price * item.quantity).toStringAsFixed(2)}',
                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                   ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder() async {
    String? selectedReason = 'Changed my mind';
    final TextEditingController notesController = TextEditingController();

    final result = await showDialog<Map<String, String>?>(
      context: context, 
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Cancel Order'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Please select a reason for cancellation:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...['Size Mismatch', 'Found better price', 'Changed my mind', 'Other'].map((reason) => 
                    RadioListTile<String>(
                      title: Text(reason),
                      value: reason,
                      groupValue: selectedReason,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setDialogState(() {
                          selectedReason = val;
                        });
                      },
                    )
                  ).toList(),
                  const SizedBox(height: 16),
                  const Text('Additional Information (Optional):', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Tell us more...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Go Back')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, {
                  'reason': selectedReason ?? 'Other',
                  'notes': notesController.text,
                }), 
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                child: const Text('Confirm Cancellation')
              )
            ],
          );
        }
      )
    );
    
    if (result != null) {
      setState(() { _isLoading = true; });
      try {
         await Provider.of<AppState>(context, listen: false).cancelOrder(
           widget.orderId,
           reason: result['reason'],
           notes: result['notes'],
         );
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order cancelled successfully.')));
           _fetchOrderDetails(); // Reload to show updated status
         }
      } catch(e) {
         if (mounted) {
           setState(() { _isLoading = false; }); // only stop loading on error, success reloads via fetch
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception:", ""))));
         }
      }
    }
  }

  Future<void> _returnOrder() async {
    // 1. Select Item to Return
    // If only 1 item, auto-select it. If multiple, show dialog.
    OrderItem? selectedItem;
    
    if (_order!.items.length == 1) {
      selectedItem = _order!.items.first;
    } else {
      selectedItem = await showDialog<OrderItem>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Item to Return'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _order!.items.length,
              itemBuilder: (context, index) {
                final item = _order!.items[index];
                return ListTile(
                  leading: item.image != null 
                      ? SizedBox(width: 40, height: 40, child: CachedNetworkImage(imageUrl: item.image!, fit: BoxFit.cover)) 
                      : const Icon(Icons.image),
                  title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('Qty: ${item.quantity}'),
                  onTap: () => Navigator.pop(context, item),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('Cancel')
            ),
          ],
        ),
      );
    }

    if (selectedItem == null) return; // User cancelled item selection

    // 2. Select Reason & Type
    String selectedType = 'return';
    String? selectedReason = 'Defective';
    final TextEditingController descController = TextEditingController();

    final result = await showDialog<Map<String, String>?>(
      context: context, 
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Return/Replace: ${selectedItem!.name}', style: const TextStyle(fontSize: 16)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text('I want to:', style: TextStyle(fontWeight: FontWeight.bold)),
                   Row(
                     children: [
                       Expanded(
                         child: RadioListTile<String>(
                           title: const Text('Return'),
                           value: 'return',
                           groupValue: selectedType,
                           onChanged: (val) => setDialogState(() => selectedType = val!),
                           contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                         ),
                       ),
                       Expanded(
                         child: RadioListTile<String>(
                           title: const Text('Replace'),
                           value: 'replacement',
                           groupValue: selectedType,
                           onChanged: (val) => setDialogState(() => selectedType = val!),
                           contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                         ),
                       ),
                     ],
                   ),
                   const Divider(),
                   const Text('Reason:', style: TextStyle(fontWeight: FontWeight.bold)),
                   ...['Defective', 'Wrong Item', 'Size Mismatch', 'Not as Described', 'Other'].map((r) => 
                     RadioListTile<String>(
                       title: Text(r),
                       value: r,
                       groupValue: selectedReason,
                       onChanged: (val) => setDialogState(() => selectedReason = val),
                       contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                     )
                   ).toList(),
                   const SizedBox(height: 16),
                   TextField(
                     controller: descController,
                     maxLines: 2,
                     decoration: const InputDecoration(
                       labelText: 'Additional Description',
                       border: OutlineInputBorder(),
                     ),
                   ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, {
                  'type': selectedType,
                  'reason': selectedReason!,
                  'description': descController.text,
                }), 
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple, foregroundColor: Colors.white),
                child: const Text('Submit Request')
              )
            ],
          );
        }
      )
    );
    
    if (result != null) {
      setState(() { _isLoading = true; });
      try {
         // Create the return request via new API
         await Provider.of<AppState>(context, listen: false).createReturnRequest(
           widget.orderId,
           selectedItem!.id, 
           result['type']!,
           result['reason']!,
           result['description']!,
         );
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request submitted successfully.')));
           _fetchOrderDetails(); 
         }
      } catch(e) {
         if (mounted) {
            setState(() { _isLoading = false; }); 
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception:", ""))));
         }
      }
    }
  }

  Widget _buildSummaryCard(Order order, String currency) {
    double subtotal = order.items.fold(0, (sum, i) => sum + (i.price * i.quantity));
    double shipping = order.totalPrice - subtotal;
    if (shipping < 0) shipping = 0;

    // Check cancellable
    bool canCancel = (order.status == 'Placed' || order.status == 'Pending Payment') && order.status != 'Cancelled';
    bool canReturn = order.status == 'Completed';
    bool isReturned = order.status.contains('Return');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _summaryRow('Subtotal', '$currency${subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 12),
          _summaryRow('Shipping', '$currency${shipping.toStringAsFixed(2)}'),
          const SizedBox(height: 12),
          _summaryRow('Status', order.status, color: order.status == 'Cancelled' ? Colors.red : (order.status.contains('Return') ? Colors.orange : (order.paymentStatus == 'Success' ? Colors.green : Colors.orange))),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text('$currency${order.totalPrice.toStringAsFixed(2)}', 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppTheme.primaryPurple)
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Method: ${order.paymentMethod}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          
          if (canCancel) ...[
             const SizedBox(height: 32),
             SizedBox(
               width: double.infinity,
               child: OutlinedButton.icon(
                 onPressed: _cancelOrder,
                 icon: const Icon(Icons.cancel, color: Colors.red),
                 label: const Text('Cancel Order', style: TextStyle(color: Colors.red)),
                 style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                 ),
               ),
             )
          ],

          if (canReturn) ...[
             const SizedBox(height: 32),
             SizedBox(
               width: double.infinity,
               child: OutlinedButton.icon(
                 onPressed: _returnOrder,
                 icon: const Icon(Icons.assignment_return, color: AppTheme.primaryPurple),
                 label: const Text('Return Order', style: TextStyle(color: AppTheme.primaryPurple)),
                 style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primaryPurple),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                 ),
               ),
             )
          ],

          if (isReturned && order.returnTrackingNumber != null) ...[
             const SizedBox(height: 24),
             const Divider(),
             const SizedBox(height: 16),
             const Text('Return Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
             const SizedBox(height: 8),
             Text('Tracking: ${order.returnTrackingNumber}'),
             if (order.returnLabelUrl != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('Label URL: ${order.returnLabelUrl ?? "N/A"}', style: const TextStyle(color: Colors.blue, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                )
          ],

          if (order.status == 'Cancelled') ...[
             const SizedBox(height: 24),
             const Divider(),
             const SizedBox(height: 16),
             Row(
               children: [
                 const Icon(Icons.info_outline, color: Colors.red, size: 20),
                 const SizedBox(width: 8),
                 const Text('Cancellation Reason', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
               ],
             ),
             const SizedBox(height: 8),
             Text(order.cancelReason ?? 'No reason provided', style: const TextStyle(fontWeight: FontWeight.w500)),
             if (order.cancelNotes != null && order.cancelNotes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text('Note: ${order.cancelNotes}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                )
          ]
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 15)),
        Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: color ?? Colors.black)),
      ],
    );
  }

  Widget _buildAddressCard(Order order) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Shipping Address', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(order.shippingName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(order.shippingAddressLine1),
          if (order.shippingAddressLine2 != null && order.shippingAddressLine2!.isNotEmpty)
            Text(order.shippingAddressLine2!),
          Text('${order.shippingDistrict}, ${order.shippingState} - ${order.shippingPincode}'),
          Text(order.shippingCountry),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.phone, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(order.shippingPhone),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(Order order) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Status: ${order.status}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 24),
          
          FutureBuilder<Map<String, dynamic>>(
            future: Provider.of<AppState>(context, listen: false).apiService.fetchShipmentTracking(order.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));
              }    
              
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                 // Fallback to simple status steps if no tracking
                 return _buildSimpleStatusSteps(order);
              }

              final data = snapshot.data!;
              final events = (data['events'] as List?) ?? [];
              
              if (events.isEmpty) return _buildSimpleStatusSteps(order);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Tracking ID: ${data['trackingNumber'] ?? order.trackingNumber ?? 'N/A'}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: events.length,
                    separatorBuilder: (ctx, i) => Container(
                      margin: const EdgeInsets.only(left: 6),
                      height: 20, 
                      width: 2, 
                      color: Colors.grey[300]
                    ),
                    itemBuilder: (ctx, i) {
                       final e = events[i];
                       return Row(
                         crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 14, height: 14,
                            decoration: BoxDecoration(color: AppTheme.primaryPurple, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e['description'] ?? e['status'] ?? 'Update', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text("${e['city'] ?? ''} ${e['state'] ?? ''}".trim(), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                Text(e['date'] ?? '', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                              ],
                            ),
                          )
                        ],
                       );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStatusSteps(Order order) {
    if (order.status == 'Cancelled') return const Text("This order has been cancelled.", style: TextStyle(color: Colors.red));
    
    final statuses = ['Placed', 'Ready to Dispatch', 'In Transit', 'Completed'];
    int currentStep = 0;
    if (statuses.contains(order.status)) {
      currentStep = statuses.indexOf(order.status);
    } else if (order.status == 'Processing') {
      currentStep = 1;
    }

    return Row(
      children: List.generate(statuses.length, (index) {
          bool isCompleted = index <= currentStep;
          bool isLast = index == statuses.length - 1;
          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: isCompleted ? AppTheme.primaryPurple : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(isCompleted ? Icons.check : Icons.circle, color: Colors.white, size: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(statuses[index], style: TextStyle(fontSize: 10, color: isCompleted ? Colors.black : Colors.grey)),
                  ],
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isCompleted && index < currentStep ? AppTheme.primaryPurple : Colors.grey[300],
                      margin: const EdgeInsets.only(bottom: 20),
                    ),
                  ),
              ],
            ),
          );
      }),
    );
  }
}
