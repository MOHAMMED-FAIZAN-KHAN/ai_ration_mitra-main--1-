// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/fps_operations_provider.dart';
import '../../widgets/citizen/quick_action_card.dart';
import '../../widgets/common/statistic_card.dart';
import 'entitlement_screen.dart';
import 'fps_locator.dart';
import 'profile_screen.dart'; // This imports the external ProfileScreen
import 'distribution_history.dart';
import 'upcoming_distribution.dart';
import 'family_members_screen.dart';

class CitizenDashboard extends StatefulWidget {
  const CitizenDashboard({super.key});

  @override
  State<CitizenDashboard> createState() => _CitizenDashboardState();
}

class _CitizenDashboardState extends State<CitizenDashboard> {
  int _currentIndex = 0;

  // No 'const' here because the constructors are not constant
  final List<Widget> _screens = [
    const _HomeScreen(), // If _HomeScreen is const, keep const; otherwise remove const
    const EntitlementsScreen(
        showAppBar: false), // Embedded under dashboard app bar
    const FpsLocatorScreen(
        showAppBar: false), // Embedded under dashboard app bar
    const ProfileScreen(), // This is the imported ProfileScreen (should be const)
  ];

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return WillPopScope(
      onWillPop: () => _confirmLogout(context),
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.translate('app_title')),
          actions: [
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () => Navigator.pushNamed(context, '/ai-assistant'),
            ),
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () =>
                  Navigator.pushNamed(context, '/citizen/notifications'),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: _screens[_currentIndex],
            ),
            if (_currentIndex != 3)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.history),
                  label: const Text('View Distribution History'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DistributionHistory(),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.saffron,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: loc.translate('home'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_basket_outlined),
              label: loc.translate('entitlements'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.location_on_outlined),
              label: loc.translate('fps_locator'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outlined),
              label: loc.translate('profile'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Do you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text(
                  'Yes',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (shouldLogout) {
      final authProvider = context.read<AuthProvider>();
      await authProvider.logout();
      if (!mounted) {
        return false;
      }
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
    return false;
  }
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen(); // Ensure this is const

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final ops = Provider.of<FPSOperationsProvider>(context);
    final beneficiary = ops.beneficiaryForCitizen(authProvider.currentUser);
    final upcomingList = beneficiary == null
        ? const []
        : ops.upcomingDistributionForCard(beneficiary.cardNumber);
    final nextDistribution = upcomingList.isEmpty ? null : upcomingList.first;
    final bannerText = nextDistribution == null
        ? 'No upcoming ration collection is scheduled'
        : 'Next ration collection on ${_formatDate(nextDistribution.date)}';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.translate('citizen_portal'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.saffron,
            ),
          ),
          const SizedBox(height: 20),
          // Update Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.saffron.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.saffron),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_active,
                  color: AppColors.saffron,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'New Update Available',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        bannerText,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // User Info Card
          _buildUserInfoCard(context),
          const SizedBox(height: 20),
          // Quick Actions
          Text(
            loc.translate('quick_actions'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              QuickActionCard(
                icon: Icons.list_alt,
                title: loc.translate('my_entitlements'),
                color: Colors.blue,
                onTap: () =>
                    Navigator.pushNamed(context, '/citizen/entitlement'),
              ),
              QuickActionCard(
                icon: Icons.location_searching,
                title: loc.translate('find_fps'),
                color: Colors.green,
                onTap: () =>
                    Navigator.pushNamed(context, '/citizen/fps-locator'),
              ),
              QuickActionCard(
                icon: Icons.notifications,
                title: loc.translate('Notifications'),
                color: Colors.orange,
                onTap: () =>
                    Navigator.pushNamed(context, '/citizen/notifications'),
              ),
              QuickActionCard(
                icon: Icons.history,
                title: loc.translate('upcoming_distributions'),
                color: Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UpcomingDistributionPlanner(),
                    ),
                  );
                },
              ),
              QuickActionCard(
                icon: Icons.feedback,
                title: loc.translate('grievances'),
                color: Colors.red,
                onTap: () =>
                    Navigator.pushNamed(context, '/citizen/grievances'),
              ),
              QuickActionCard(
                icon: Icons.family_restroom,
                title: 'Family Members',
                color: Colors.indigo,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FamilyMembersScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 30),
          // System Overview
          Text(
            loc.translate('system_overview'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatisticCard(
                value: '2,736+',
                label: loc.translate('fps_shops'),
                icon: Icons.store,
                color: Colors.blue,
              ),
              StatisticCard(
                value: '5.4L+',
                label: loc.translate('beneficiaries'),
                icon: Icons.people,
                color: Colors.green,
              ),
              StatisticCard(
                value: '98%',
                label: loc.translate('monthly_distribution'),
                icon: Icons.trending_up,
                color: Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    // Use dynamic data or fallback to defaults
    final userNameRaw = (user?.name ?? '').trim();
    final uidRaw = (user?.uid ?? '').trim();
    final categoryRaw = (user?.category ?? '').trim();
    final assignedShopRaw = (user?.assignedShop ?? '').trim();

    final userName = userNameRaw.isNotEmpty ? userNameRaw : 'Citizen User';
    final uid = uidRaw.isNotEmpty ? uidRaw : (user?.id ?? '****');
    final category = categoryRaw.isNotEmpty ? categoryRaw : 'Not provided';
    final ops = Provider.of<FPSOperationsProvider>(context, listen: false);
    final beneficiary = ops.beneficiaryForCitizen(user);
    final upcomingList = beneficiary == null
        ? const []
        : ops.upcomingDistributionForCard(beneficiary.cardNumber);
    final nextDistribution = upcomingList.isEmpty ? null : upcomingList.first;
    final assignedShop = assignedShopRaw.isNotEmpty
        ? assignedShopRaw
        : (nextDistribution?.shopName ?? 'FPS Shop');
    final nextRationDate = nextDistribution == null
        ? 'Not scheduled'
        : _formatDate(nextDistribution.date);
    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey[50]!],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Name
              Row(
                children: [
                  const Icon(Icons.person, size: 40, color: AppColors.saffron),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Member',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // UID and Category Row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.saffron.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.saffron.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'UID',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            uid,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          Navigator.pushNamed(context, '/citizen/profile'),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green[400]!, Colors.green[600]!],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Category',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    category,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.edit,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Ration Date and Assigned Shop
              Row(
                children: [
                  Expanded(
                    child: _buildInfoRow(
                      icon: Icons.calendar_today,
                      label: 'Next Ration',
                      value: nextRationDate,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoRow(
                      icon: Icons.store,
                      label: 'Assigned Shop',
                      value: assignedShop,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
