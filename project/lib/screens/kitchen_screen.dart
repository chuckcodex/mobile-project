import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

class KitchenScreen extends StatefulWidget {
  final String businessId;

  const KitchenScreen({Key? key, required this.businessId}) : super(key: key);

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _player = AudioPlayer();
  List<Map<String, dynamic>> _orders = [];
  Timer? _timer;

  late AnimationController _animationController;
  late Animation<Color?> _flashAnimation;

  @override
  void initState() {
    super.initState();
    _fetchKitchenOrders();
    _subscribeToKitchenOrders();

    // Flash animation for pending orders
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _flashAnimation = ColorTween(
      begin: Colors.red.shade300,
      end: Colors.red.shade100,
    ).animate(_animationController);

    // Update elapsed times every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      setState(() {}); // triggers rebuild to refresh elapsed time
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchKitchenOrders() async {
    final response = await _supabase
        .from('orders')
        .select()
        .eq('business_id', widget.businessId)
        .inFilter('status', ['pending', 'preparing', 'ready'])
        .order('created_at', ascending: true);

    setState(() {
      _orders = List<Map<String, dynamic>>.from(response);
    });
  }

  void _subscribeToKitchenOrders() {
    _supabase
        .channel('orders-changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'orders',
          // filter can be re-added once fixed
          callback: (payload) {
            _playNewOrderSound();
            _fetchKitchenOrders();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          // filter can be re-added once fixed
          callback: (payload) {
            _fetchKitchenOrders();
          },
        )
        .subscribe();
  }

  Future<void> _playNewOrderSound() async {
    await _player.play(AssetSource('sounds/new_order.mp3'));
  }

  Future<void> _advanceStatus(String orderId, String currentStatus) async {
    final nextStatus = _getNextStatus(currentStatus);
    if (nextStatus == null) return;

    await _supabase
        .from('orders')
        .update({'status': nextStatus})
        .eq('id', orderId);
  }

  String? _getNextStatus(String current) {
    const flow = ['pending', 'preparing', 'ready'];
    final index = flow.indexOf(current);
    if (index == -1 || index == flow.length - 1) return null;
    return flow[index + 1];
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'preparing':
        return Colors.amber.shade300;
      case 'ready':
        return Colors.green.shade300;
      default:
        return Colors.grey.shade300;
    }
  }

  String _elapsedTimeText(String createdAt) {
    final created = DateTime.parse(createdAt).toLocal();
    final diff = DateTime.now().difference(created);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    return '${hours}h ${minutes}m ago';
  }

  Color _elapsedTimeColor(String createdAt) {
    final created = DateTime.parse(createdAt).toLocal();
    final diff = DateTime.now().difference(created);

    if (diff.inMinutes < 10) return Colors.green.shade800;
    if (diff.inMinutes < 20) return Colors.orange.shade800;
    return Colors.red.shade800;
  }

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = MediaQuery.of(context).size.width > 1000 ? 3 : 2;

    return Scaffold(
      appBar: AppBar(title: const Text('Kitchen Dashboard')),
      body: _orders.isEmpty
          ? const Center(child: Text('No active orders'))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                final isPending = order['status'] == 'pending';
                final urgencyColor = _elapsedTimeColor(order['created_at']);

                return AnimatedBuilder(
                  animation: _flashAnimation,
                  builder: (context, child) {
                    return Card(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: urgencyColor, width: 3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      color: isPending
                          ? _flashAnimation.value
                          : _statusColor(order['status']),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order #${order['id']}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Status: ${order['status']}',
                              style: const TextStyle(fontSize: 18),
                            ),
                            Text(
                              'Placed: ${_elapsedTimeText(order['created_at'])}',
                              style: TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.bold,
                                color: urgencyColor,
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                                textStyle: const TextStyle(fontSize: 18),
                              ),
                              onPressed: () => _advanceStatus(
                                order['id'],
                                order['status'],
                              ),
                              child: Text(
                                _getNextStatus(order['status']) ?? 'Done',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
