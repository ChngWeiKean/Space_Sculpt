import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:space_sculpt_mobile_app/src/widgets/title.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../colors.dart';
import '../../../routes.dart';

class CustomerOrderStatus extends StatefulWidget {
  final String orderId;

  const CustomerOrderStatus({super.key, required this.orderId});

  @override
  _CustomerOrderStatusState createState() => _CustomerOrderStatusState();
}

class _CustomerOrderStatusState extends State<CustomerOrderStatus> {
  late DatabaseReference _dbRef;
  late User _currentUser;
  Map<dynamic, dynamic>? _orderData;
  Map<dynamic, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _dbRef = FirebaseDatabase.instance.ref();
    _currentUser = FirebaseAuth.instance.currentUser!;
    _fetchData();
  }

  @override
  void dispose() {
    _dbRef.onDisconnect();
    super.dispose();
  }

  Future<void> _fetchData() async {
    await Future.wait([
      _fetchOrderData(),
      _fetchUserData(),
    ]);
  }

  Future<void> _fetchOrderData() async {
    final snapshot = await _dbRef.child('orders/${widget.orderId}').get();
    if (snapshot.exists) {
      _orderData = snapshot.value as Map<dynamic, dynamic>;
      setState(() {});
      await _fetchDriverData();
    }
  }

  Future<void> _fetchDriverData() async {
    if (_orderData != null) {
      final snapshot = await _dbRef.child('drivers/${_orderData!['driver_id']}').get();
      if (snapshot.exists) {
        final driverData = snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _orderData!['driver_data'] = driverData;
        });
      }
    }
  }

  Future<void> _fetchUserData() async {
    if (_currentUser != null) {
      final snapshot = await _dbRef.child('users/${_currentUser.uid}').get();
      if (snapshot.exists) {
        final userData = snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _userData = userData;
        });
      }
    }
  }

  String _getStatusDescription(String status) {
    switch (status) {
      case 'Pending':
        return 'Your order is being processed.';
      case 'Ready For Shipping':
        return 'Your order is ready to be shipped.';
      case 'Shipping':
        return 'Your order is on the way.';
      case 'Arrived':
        return 'Your order has arrived at the destination.';
      case 'On Hold':
        return 'Your order is currently on hold.';
      case 'Resolved':
        return 'Your issue has been resolved.';
      case 'Completed':
        return 'Your order is completed.';
      default:
        return 'We are preparing your order.';
    }
  }

  String _getCurrentStatus(Map<dynamic, dynamic> status) {
    if (status == null) return 'Pending';

    // Sort statuses by date (newest first)
    final sortedKeys = status.keys.toList()..sort((a, b) {
      final aDate = DateTime.parse(status[a]);
      final bDate = DateTime.parse(status[b]);
      return bDate.compareTo(aDate);
    });

    // Check status in priority order
    for (var key in sortedKeys) {
      if (key == 'Completed') return 'Completed';
      if (key == 'Resolved') return 'Resolved';
      if (key == 'OnHold') return 'On Hold';
      if (key == 'Arrived') return 'Arrived';
      if (key == 'Shipping') return 'Shipping';
      if (key == 'ReadyForShipping') return 'Ready For Shipping';
      if (key == 'Pending') return 'Pending';
    }

    return 'Pending';
  }

  String _getDetailedStatusDescription(String status, String date) {
    switch (status) {
      case 'Pending':
        return '$date - Your order is currently being processed by our system.';
      case 'Ready For Shipping':
        return '$date - Your order has been packed and is ready for shipping.';
      case 'Shipping':
        return '$date - Your order is on its way!';
      case 'Arrived':
        return '$date - Your order has arrived at the destination.';
      case 'On Hold':
        return '$date - Your order is currently on hold.';
      case 'Resolved':
        return '$date - Your issue has been resolved.';
      case 'Completed':
        return '$date - Your order has been successfully completed.';
      default:
        return '$date - We are preparing your order.';
    }
  }

  Widget _buildTimelineItem({
    required String status,
    required String date,
    required bool isActive,
    required bool isFirst,
    required bool isLast,
    bool isProblem = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            if (!isFirst)
              Container(
                width: 2,
                height: 20,
                color: isActive
                    ? isProblem ? Colors.red : AppColors.secondary
                    : Colors.grey[300],
              ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? isProblem ? Colors.red : AppColors.secondary
                    : Colors.grey[300],
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
              ),
              child: isActive
                  ? Icon(
                isProblem ? Icons.warning : Icons.check,
                size: 12,
                color: Colors.white,
              )
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 20,
                color: isActive
                    ? isProblem ? Colors.red : AppColors.secondary
                    : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                status,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.black : Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                date,
                style: TextStyle(
                  fontSize: 14,
                  color: isActive ? Colors.grey[600] : Colors.grey[400],
                ),
              ),
              if (isActive)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _getDetailedStatusDescription(status, date),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomTimeline() {
    if (_orderData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final statusMap = _orderData!['completion_status'] as Map<dynamic, dynamic>? ?? {};
    final DateFormat formatter = DateFormat('dd MMM yyyy');

    // Define all possible statuses in order
    const allStatuses = [
      {'key': 'Pending', 'title': 'Order Placed'},
      {'key': 'ReadyForShipping', 'title': 'Ready For Shipping'},
      {'key': 'Shipping', 'title': 'Shipped'},
      {'key': 'Arrived', 'title': 'Delivered'},
      {'key': 'OnHold', 'title': 'On Hold'},
      {'key': 'Resolved', 'title': 'Resolved'},
      {'key': 'Completed', 'title': 'Completed'},
    ];

    // Determine the current active status
    final currentStatus = _getCurrentStatus(statusMap);

    return Column(
      children: allStatuses.map((status) {
        final statusKey = status['key']!;
        final statusTitle = status['title']!;
        final hasStatus = statusMap[statusKey] != null;
        final isActive = (statusKey == 'Pending' && currentStatus == 'Pending') ||
            (statusKey == 'ReadyForShipping' && currentStatus == 'Ready For Shipping') ||
            (statusKey == 'Shipping' && currentStatus == 'Shipping') ||
            (statusKey == 'Arrived' && currentStatus == 'Arrived') ||
            (statusKey == 'OnHold' && currentStatus == 'On Hold') ||
            (statusKey == 'Resolved' && currentStatus == 'Resolved') ||
            (statusKey == 'Completed' && currentStatus == 'Completed');

        final isProblem = statusKey == 'OnHold';
        final date = hasStatus
            ? formatter.format(DateTime.parse(statusMap[statusKey]))
            : '';

        // Only show status if it exists or is the current status
        if (hasStatus || isActive) {
          return _buildTimelineItem(
            status: statusTitle,
            date: date,
            isActive: isActive,
            isFirst: allStatuses.first == status,
            isLast: allStatuses.last == status,
            isProblem: isProblem,
          );
        } else {
          return const SizedBox.shrink();
        }
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _orderData == null && _userData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            const TitleBar(title: 'Delivery Details', hasBackButton: true),
            Container(
              height: 120,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getStatusDescription(_getCurrentStatus(_orderData?['completion_status'] ?? {})),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18.0,
                        fontFamily: 'Poppins_Bold',
                      ),
                    ),
                    const SizedBox(height: 5),
                    if (_orderData?['shipping_date'] != null)
                      Text(
                        'Get by ${_orderData!['shipping_date']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                          fontFamily: 'Poppins_Medium',
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildCustomTimeline(),
            ),
          ],
        ),
      ),
    );
  }
}