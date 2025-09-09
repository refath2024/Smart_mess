import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/premium_request.dart';
import '../../services/premium_request_service.dart';
import '../../theme_provider.dart';
import 'package:provider/provider.dart';

class AdminPremiumRequestsScreen extends StatefulWidget {
  const AdminPremiumRequestsScreen({super.key});

  @override
  State<AdminPremiumRequestsScreen> createState() => _AdminPremiumRequestsScreenState();
}

class _AdminPremiumRequestsScreenState extends State<AdminPremiumRequestsScreen>
    with SingleTickerProviderStateMixin {
  final PremiumRequestService _premiumRequestService = PremiumRequestService();
  late TabController _tabController;
  
  String _filterStatus = 'all';
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _premiumRequestService.getPremiumRequestStats();
    setState(() {
      _stats = stats;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Request Management'),
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.blue[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Pending', icon: Icon(Icons.pending_actions)),
            Tab(text: 'All Requests', icon: Icon(Icons.list)),
            Tab(text: 'Statistics', icon: Icon(Icons.analytics)),
            Tab(text: 'Today\'s Orders', icon: Icon(Icons.today)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingRequestsTab(),
          _buildAllRequestsTab(),
          _buildStatisticsTab(),
          _buildTodayOrdersTab(),
        ],
      ),
    );
  }

  Widget _buildPendingRequestsTab() {
    return StreamBuilder<List<PremiumRequest>>(
      stream: _premiumRequestService.getPendingPremiumRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No pending premium requests',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            return _buildRequestCard(snapshot.data![index], showActions: true);
          },
        );
      },
    );
  }

  Widget _buildAllRequestsTab() {
    return StreamBuilder<List<PremiumRequest>>(
      stream: _premiumRequestService.getAllPremiumRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No premium requests found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Filter Options
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('Filter by status: '),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _filterStatus,
                    items: [
                      const DropdownMenuItem(value: 'all', child: Text('All')),
                      const DropdownMenuItem(value: 'pending', child: Text('Pending')),
                      const DropdownMenuItem(value: 'approved', child: Text('Approved')),
                      const DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filterStatus = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
            // Requests List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final request = snapshot.data![index];
                  if (_filterStatus != 'all' && request.status != _filterStatus) {
                    return const SizedBox.shrink();
                  }
                  return _buildRequestCard(request, showActions: request.status == 'pending');
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatisticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Requests',
                  _stats['total_requests']?.toString() ?? '0',
                  Icons.request_page,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Pending',
                  _stats['pending_requests']?.toString() ?? '0',
                  Icons.pending,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Approved',
                  _stats['approved_requests']?.toString() ?? '0',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Rejected',
                  _stats['rejected_requests']?.toString() ?? '0',
                  Icons.cancel,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Revenue',
                  '\$${(_stats['total_revenue']?.toDouble() ?? 0.0).toStringAsFixed(2)}',
                  Icons.attach_money,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Approval Rate',
                  '${(_stats['approval_rate']?.toDouble() ?? 0.0).toStringAsFixed(1)}%',
                  Icons.trending_up,
                  Colors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Refresh Button
          ElevatedButton.icon(
            onPressed: _loadStats,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Statistics'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayOrdersTab() {
    return FutureBuilder<List<PremiumRequest>>(
      future: _premiumRequestService.getApprovedRequestsForDate(DateTime.now()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.restaurant,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No premium orders for today',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        // Group by meal type
        final groupedOrders = <String, List<PremiumRequest>>{};
        for (final request in snapshot.data!) {
          groupedOrders.putIfAbsent(request.mealType, () => []).add(request);
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: groupedOrders.entries.map((entry) {
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.key.toUpperCase()} (${entry.value.length} orders)',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...entry.value.map((request) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  request.preferredMeal,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Text('${request.userRank} ${request.userName}'),
                                Text('BA: ${request.baNumber}'),
                              ],
                            ),
                          ),
                          if (request.additionalCost != null)
                            Text(
                              '\$${request.additionalCost!.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[600],
                              ),
                            ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(PremiumRequest request, {bool showActions = false}) {
    Color statusColor;
    IconData statusIcon;
    
    switch (request.status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${request.preferredMeal} (${request.mealType.toUpperCase()})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (request.additionalCost != null)
                  Text(
                    '\$${request.additionalCost!.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[600],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Requested by: ${request.userRank} ${request.userName}'),
            Text('BA Number: ${request.baNumber}'),
            Text('Date: ${DateFormat('EEEE, MMM dd, yyyy').format(request.requestedDate)}'),
            Text('Status: ${request.status.toUpperCase()}'),
            if (request.reason.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Reason: ${request.reason}'),
            ],
            if (request.approvedBy != null) ...[
              const SizedBox(height: 4),
              Text('Processed by: ${request.approvedBy}'),
            ],
            if (request.rejectionReason != null) ...[
              const SizedBox(height: 4),
              Text(
                'Rejection reason: ${request.rejectionReason}',
                style: const TextStyle(color: Colors.red),
              ),
            ],
            
            if (showActions) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveRequest(request),
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _rejectRequest(request),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _approveRequest(PremiumRequest request) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Request'),
        content: Text(
          'Approve premium meal request for ${request.preferredMeal} by ${request.userName}?\n\nCost: \$${request.additionalCost?.toStringAsFixed(2) ?? '0.00'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _premiumRequestService.approvePremiumRequest(
        request.id,
        'Admin', // TODO: Get actual admin name from context
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadStats(); // Refresh stats
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to approve request'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectRequest(PremiumRequest request) async {
    final reasonController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reject premium meal request for ${request.preferredMeal} by ${request.userName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                Navigator.of(context).pop(reasonController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (result != null) {
      final success = await _premiumRequestService.rejectPremiumRequest(
        request.id,
        'Admin', // TODO: Get actual admin name from context
        result,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request rejected successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadStats(); // Refresh stats
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to reject request'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}