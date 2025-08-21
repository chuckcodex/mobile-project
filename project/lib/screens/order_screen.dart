import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderScreen extends StatefulWidget {
  final String businessId; // Pass this in when navigating to the screen

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
    _subscribeToOrders();
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

  void _subscribeToOrders() {
    _supabase
        .channel('public:orders')
        .on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(
            event: '*',
            schema: 'public',
            table: 'orders',
            filter: 'business_id=eq.${widget.businessId}',
          ),
          (payload, [ref]) {
            _fetchOrders();
          },
        )
        .subscribe();
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
                    trailing: _statusChip(order['status']),
                  ),
                );
              },
            ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'preparing':
        color = Colors.blue;
        break;
      case 'ready':
        color = Colors.green;
        break;
      case 'completed':
        color = Colors.grey;
        break;
      default:
        color = Colors.black;
    }
    return Chip(
      label: Text(status),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color),
    );
  }
}
