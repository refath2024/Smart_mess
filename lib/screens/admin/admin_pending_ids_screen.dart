import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

import 'admin_home_screen.dart';
import 'admin_users_screen.dart';
import 'admin_shopping_history.dart';
import 'admin_voucher_screen.dart';
import 'admin_inventory_screen.dart';
import 'admin_messing_screen.dart';
import 'admin_staff_state_screen.dart';
import 'admin_dining_member_state.dart';
import 'admin_payment_history.dart';
import 'admin_bill_screen.dart';
import 'admin_monthly_menu_screen.dart';
import 'admin_menu_vote_screen.dart';
import '../../role_screen_access.dart';
import 'admin_meal_state_screen.dart';
import 'admin_login_screen.dart';
import '../../services/admin_auth_service.dart';
import '../../services/emailjs_service.dart';
import '../../providers/language_provider.dart';
import '../../l10n/app_localizations.dart';

class AdminPendingIdsScreen extends StatefulWidget {
  const AdminPendingIdsScreen({super.key});

  @override
  State<AdminPendingIdsScreen> createState() => _AdminPendingIdsScreenState();
}

class _AdminPendingIdsScreenState extends State<AdminPendingIdsScreen> {
  List<Widget> _buildRoleBasedSidebarTiles(BuildContext context) {
    final role = _currentUserData?['role'] ?? '';
    final allowedScreens = getAllowedAdminScreensForRole(role);
    final List<Widget> tiles = [];
    for (final screenId in allowedScreens) {
      switch (screenId) {
        case AdminScreenIds.home:
          tiles.add(_buildSidebarTile(
            icon: Icons.dashboard,
            title: AppLocalizations.of(context)!.home,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const AdminHomeScreen()),
              );
            },
          ));
          break;
        case AdminScreenIds.users:
          tiles.add(_buildSidebarTile(
            icon: Icons.people,
            title: AppLocalizations.of(context)!.users,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AdminUsersScreen()),
              );
            },
          ));
          break;
        case AdminScreenIds.pendingIds:
          tiles.add(_buildSidebarTile(
            icon: Icons.pending,
            title: AppLocalizations.of(context)!.pendingIds,
            onTap: () => Navigator.pop(context),
            selected: true,
          ));
          break;
        case AdminScreenIds.shoppingHistory:
          tiles.add(_buildSidebarTile(
            icon: Icons.history,
            title: AppLocalizations.of(context)!.shoppingHistory,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const AdminShoppingHistoryScreen()),
              );
            },
          ));
          break;
        case AdminScreenIds.voucher:
          tiles.add(_buildSidebarTile(
            icon: Icons.receipt,
            title: AppLocalizations.of(context)!.voucherList,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const AdminVoucherScreen()),
              );
            },
          ));
          break;
        case AdminScreenIds.inventory:
          tiles.add(_buildSidebarTile(
            icon: Icons.storage,
            title: AppLocalizations.of(context)!.inventory,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const AdminInventoryScreen()),
              );
            },
          ));
          break;
        case AdminScreenIds.messing:
          tiles.add(_buildSidebarTile(
            icon: Icons.food_bank,
            title: AppLocalizations.of(context)!.messing,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const AdminMessingScreen()),
              );
            },
          ));
          break;
        case AdminScreenIds.monthlyMenu:
          tiles.add(_buildSidebarTile(
            icon: Icons.menu_book,
            title: AppLocalizations.of(context)!.monthlyMenu,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const EditMenuScreen()),
              );
            },
          ));
          break;
        case AdminScreenIds.mealState:
          tiles.add(_buildSidebarTile(
            icon: Icons.analytics,
            title: AppLocalizations.of(context)!.mealState,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const AdminMealStateScreen()),
              );
            },
          ));
          break;
        case AdminScreenIds.menuVote:
          tiles.add(_buildSidebarTile(
            icon: Icons.thumb_up,
            title: AppLocalizations.of(context)!.menuVote,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MenuVoteScreen()),
              );
            },
          ));
          break;
        case AdminScreenIds.bills:
          tiles.add(_buildSidebarTile(
            icon: Icons.receipt_long,
            title: AppLocalizations.of(context)!.bills,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const AdminBillScreen()),
              );
            },
          ));
          break;
        case AdminScreenIds.payments:
          tiles.add(_buildSidebarTile(
            icon: Icons.payment,
            title: AppLocalizations.of(context)!.payments,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const PaymentsDashboard()),
              );
            },
          ));
          break;
        case AdminScreenIds.diningMember:
          tiles.add(_buildSidebarTile(
            icon: Icons.people_alt,
            title: AppLocalizations.of(context)!.diningMemberState,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const DiningMemberStatePage()),
              );
            },
          ));
          break;
        case AdminScreenIds.staffState:
          tiles.add(_buildSidebarTile(
            icon: Icons.manage_accounts,
            title: AppLocalizations.of(context)!.staffState,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const AdminStaffStateScreen()),
              );
            },
          ));
          break;
        // Add more cases as needed for other screens
        default:
          break;
      }
    }
    return tiles;
  }

  final AdminAuthService _adminAuthService = AdminAuthService();

  bool _isLoading = true;
  String _currentUserName = "Admin User";
  Map<String, dynamic>? _currentUserData;

  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> pendingUsers = [];
  List<Map<String, dynamic>> filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    _fetchPendingUsers();
  }

  Future<void> _checkAuthentication() async {
    try {
      final isLoggedIn = await _adminAuthService.isAdminLoggedIn();

      if (!isLoggedIn) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
            (route) => false,
          );
        }
        return;
      }

      // Get current admin data
      final userData = await _adminAuthService.getCurrentAdminData();
      if (userData != null) {
        setState(() {
          _currentUserData = userData;
          _currentUserName = userData['name'] ?? 'Admin User';
          _isLoading = false;
        });
      } else {
        // User data not found, redirect to login
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      // Authentication error, redirect to login
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _fetchPendingUsers() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('user_requests')
          .where('approved', isEqualTo: false)
          .where('rejected', isEqualTo: false)
          .get();

      final docs = snapshot.docs;

      setState(() {
        pendingUsers = docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'ba_no': data['ba_no'] ??
                data['no'] ??
                '', // Check both old and new field names
            'rank': data['rank'] ?? '',
            'name': data['name'] ?? '',
            'unit': data['unit'] ?? '',
            'email': data['email'] ?? '',
            'mobile': data['mobile'] ?? '',
            'requestedAt': data['created_at'] is Timestamp
                ? (data['created_at'] as Timestamp)
                    .toDate()
                    .toString()
                    .split(' ')[0]
                : (data['created_at'] ?? ''),
          };
        }).toList();

        filteredUsers = List.from(pendingUsers);
      });
    } catch (e) {
      debugPrint('Failed to fetch pending users: $e');
    }
  }

  void _search(String query) {
    setState(() {
      filteredUsers = pendingUsers.where((user) {
        return user.values.any(
          (value) =>
              value.toString().toLowerCase().contains(query.toLowerCase()),
        );
      }).toList();
    });
  }

  Future<void> _acceptUser(String docId) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmAccept),
        content: Text(AppLocalizations.of(context)!.acceptUserMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.accept),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Check if user document exists
      final userDoc = await FirebaseFirestore.instance
          .collection('user_requests')
          .doc(docId)
          .get();

      if (!userDoc.exists) {
        throw Exception('User document not found');
      }

      // Update user document to approved status
      await FirebaseFirestore.instance
          .collection('user_requests')
          .doc(docId)
          .update({
        'approved': true,
        'status': "active",
        'approved_at': FieldValue.serverTimestamp(),
        'approved_by': _currentUserData?['name'] ?? 'Admin',
      });

      // Get user data for email
      final userData = userDoc.data()!;
      final userEmail = userData['email'] ?? '';
      final userRank = userData['rank'] ?? '';
      final baNumber = userData['ba_no'] ?? userData['no'] ?? '';

      // Send acceptance email
      bool emailSent = false;
      if (userEmail.isNotEmpty) {
        emailSent = await EmailJSService.sendAcceptanceEmail(
          userEmail: userEmail,
          userName: userData['name'] ?? '',
          userRank: userRank,
          baNumber: baNumber,
        );
      }

      // Log activity
      final adminName = _currentUserData?['name'] ?? 'Admin';
      final userName = userData['name'] ?? '';
      final baNo = _currentUserData?['ba_no'] ?? '';
      if (baNo.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('staff_activity_log')
            .doc(baNo)
            .collection('logs')
            .add({
          'timestamp': FieldValue.serverTimestamp(),
          'actionType': 'Accept User',
          'message': '$adminName accepted $userName. Email notification: ${emailSent ? "Sent" : "Failed"}',
          'name': adminName,
        });
      }

      // Show success message with email status
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            emailSent 
              ? '${AppLocalizations.of(context)!.userAccepted} 📧 Email sent!'
              : '${AppLocalizations.of(context)!.userAccepted} ⚠️ Email failed to send.'
          ),
          duration: Duration(seconds: 6),
          backgroundColor: emailSent ? Colors.green : Colors.orange,
        ),
      );
      await _fetchPendingUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "${AppLocalizations.of(context)!.failedToAcceptUser}: $e")),
      );
    }
  }

  Future<void> _rejectUser(String docId) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmReject),
        content: Text(AppLocalizations.of(context)!.rejectUserMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.reject),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Get user data for email and log
      final userDoc = await FirebaseFirestore.instance
          .collection('user_requests')
          .doc(docId)
          .get();
      
      final userData = userDoc.data() ?? {};
      final userName = userData['name'] ?? '';
      final userEmail = userData['email'] ?? '';
      final userRank = userData['rank'] ?? '';
      final baNumber = userData['ba_no'] ?? userData['no'] ?? '';

      await FirebaseFirestore.instance
          .collection('user_requests')
          .doc(docId)
          .update({'rejected': true, 'status': "rejected"});

      // Send rejection email
      bool emailSent = false;
      if (userEmail.isNotEmpty) {
        emailSent = await EmailJSService.sendRejectionEmail(
          userEmail: userEmail,
          userName: userName,
          userRank: userRank,
          baNumber: baNumber,
          rejectionReason: 'Your application did not meet the current requirements.',
        );
      }

      // Log activity
      final adminName = _currentUserData?['name'] ?? 'Admin';
      final baNo = _currentUserData?['ba_no'] ?? '';
      if (baNo.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('staff_activity_log')
            .doc(baNo)
            .collection('logs')
            .add({
          'timestamp': FieldValue.serverTimestamp(),
          'actionType': 'Reject User',
          'message': '$adminName rejected $userName. Email notification: ${emailSent ? "Sent" : "Failed"}',
          'name': adminName,
        });
      }

      // Show success message with email status
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            emailSent 
              ? '${AppLocalizations.of(context)!.userRejected} 📧 Email sent!'
              : '${AppLocalizations.of(context)!.userRejected} ⚠️ Email failed to send.'
          ),
          duration: Duration(seconds: 6),
          backgroundColor: emailSent ? Colors.orange : Colors.red,
        ),
      );
      await _fetchPendingUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "${AppLocalizations.of(context)!.failedToRejectUser}: $e")),
      );
    }
  }

  Widget _buildSidebarTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool selected = false,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.blue.shade100,
      child: ListTile(
        selected: selected,
        selectedTileColor: Colors.blue.shade100,
        leading: Icon(
          icon,
          color: color ??
              (selected
                  ? const Color.fromARGB(255, 40, 150, 240)
                  : Colors.black),
        ),
        title: Text(title, style: TextStyle(color: color ?? Colors.black)),
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await _adminAuthService.logoutAdmin();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }

  // Debug method to test EmailJS configuration
  Future<void> _testEmailJS() async {
    try {
      // Show debug information
      await EmailJSService.debugEmailService();
      
      // Test with a sample email
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Test EmailJS'),
          content: const Text('This will send a test email. Check the debug console for detailed logs.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                
                // Test with sample data
                final success = await EmailJSService.sendAcceptanceEmail(
                  userEmail: 'smartmess2025@gmail.com', // Change this to your test email
                  userName: 'Test User',
                  userRank: 'Captain',
                  baNumber: 'TEST123',
                );
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success 
                        ? '✅ Test email sent successfully! Check the debug console for details.'
                        : '❌ Test email failed. Check the debug console for error details.',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                    duration: const Duration(seconds: 5),
                  ),
                );
              },
              child: const Text('Send Test Email'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error testing EmailJS: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        if (_isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Scaffold(
          drawer: Drawer(
            child: Column(
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF002B5B), Color(0xFF1A4D8F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundImage: AssetImage('assets/me.png'),
                        radius: 30,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentUserName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_currentUserData != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _currentUserData!['role'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'BA: ${_currentUserData!['ba_no'] ?? ''}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      ..._buildRoleBasedSidebarTiles(context),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 8,
                      top: 8,
                    ),
                    child: _buildSidebarTile(
                      icon: Icons.logout,
                      title: AppLocalizations.of(context)!.logout,
                      onTap: _logout,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
          appBar: AppBar(
            backgroundColor: const Color(0xFF002B5B),
            iconTheme: const IconThemeData(color: Colors.white),
            centerTitle: true,
            title: Text(
              AppLocalizations.of(context)!.pendingIds,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            actions: [
              // Debug EmailJS button (only shown in debug mode)
              if (kDebugMode)
                IconButton(
                  icon: const Icon(Icons.email_outlined, color: Colors.white),
                  tooltip: 'Test EmailJS',
                  onPressed: _testEmailJS,
                ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.language, color: Colors.white),
                onSelected: (String value) {
                  if (value == 'bn') {
                    languageProvider.changeLanguage(const Locale('bn'));
                  } else {
                    languageProvider.changeLanguage(const Locale('en'));
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'en',
                    child: Row(
                      children: [
                        Text('🇺🇸'),
                        const SizedBox(width: 8),
                        Text('English'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'bn',
                    child: Row(
                      children: [
                        Text('🇧🇩'),
                        const SizedBox(width: 8),
                        Text('বাংলা'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "${AppLocalizations.of(context)!.search}:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _search,
                          decoration: InputDecoration(
                            hintText:
                                "${AppLocalizations.of(context)!.search}...",
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 20,
                        headingRowHeight: 50,
                        dataRowHeight: 60,
                        headingRowColor:
                            WidgetStateProperty.all(const Color(0xFF1A4D8F)),
                        headingTextStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.1,
                          fontSize: 14,
                        ),
                        dataTextStyle: const TextStyle(
                          color: Colors.black87,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                        dividerThickness: 0.5,
                        showBottomBorder: true,
                        columns: [
                          DataColumn(
                              label:
                                  Text(AppLocalizations.of(context)!.baNumber)),
                          DataColumn(
                              label: Text(AppLocalizations.of(context)!.rank)),
                          DataColumn(
                              label: Text(AppLocalizations.of(context)!.name)),
                          DataColumn(
                              label: Text(AppLocalizations.of(context)!.unit)),
                          DataColumn(
                              label: Text(AppLocalizations.of(context)!.email)),
                          DataColumn(
                              label:
                                  Text(AppLocalizations.of(context)!.mobile)),
                          DataColumn(
                              label: Text(
                                  AppLocalizations.of(context)!.requestedAt)),
                          DataColumn(
                              label:
                                  Text(AppLocalizations.of(context)!.action)),
                        ],
                        rows: filteredUsers.map((user) {
                          final docId = user['id'] as String;
                          return DataRow(
                            color: WidgetStateProperty.resolveWith<Color?>(
                                (states) {
                              return Colors.grey.shade100;
                            }),
                            cells: [
                              DataCell(Text(user['ba_no'] ?? '')),
                              DataCell(Text(user['rank'] ?? '')),
                              DataCell(Text(user['name'] ?? '')),
                              DataCell(Text(user['unit'] ?? '')),
                              DataCell(Text(user['email'] ?? '')),
                              DataCell(Text(user['mobile'] ?? '')),
                              DataCell(Text(user['requestedAt'] ?? '')),
                              DataCell(
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _acceptUser(docId),
                                      icon: const Icon(Icons.check, size: 16),
                                      label: Text(
                                          AppLocalizations.of(context)!.accept),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade600,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: () => _rejectUser(docId),
                                      icon: const Icon(Icons.close, size: 16),
                                      label: Text(
                                          AppLocalizations.of(context)!.reject),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.shade600,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
