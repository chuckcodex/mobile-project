import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderScreen extends StatefulWidget {
  final String businessId;

  const OrderScreen({Key? key, required this.businessId}) : super(key: key);

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    // Real-time subscription temporarily disabled
  }

  Future<void> _fetchOrders() async {
    final response = await _supabase
        .from('orders')
        .select()
        .eq('business_id', widget.businessId)
        .order('created_at', ascending: false);

    setState(() {
      _orders = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> _updateOrderStatus(String orderId, String currentStatus) async {
    final nextStatus = _getNextStatus(currentStatus);
    if (nextStatus == null) return;

    await _supabase
        .from('orders')
        .update({'status': nextStatus})
        .eq('id', orderId);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order updated to "$nextStatus"')),
    );

    // Refresh list after update
    _fetchOrders();
  }

  String? _getNextStatus(String current) {
    const flow = ['pending', 'preparing', 'ready', 'completed'];
    final index = flow.indexOf(current);
    if (index == -1 || index == flow.length - 1) return null;
    return flow[index + 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: _orders.isEmpty
          ? const Center(child: Text('No orders yet'))
          : ListView.builder(
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                return Card(
                  child: ListTile(
                    title: Text('Order ID: ${order['id']}'),
                    subtitle: Text(
                      'Status: ${order['status']}\nCreated: ${order['created_at']}',
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => _updateOrderStatus(
                        order['id'],
                        order['status'],
                      ),
                      child: Text(
                        _getNextStatus(order['status']) ?? 'Done',
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
