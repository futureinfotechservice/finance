import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb && MediaQuery.of(context).size.width > 768;

    if (isWeb) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // Top Bar for Web
            _buildWebTopBar(),
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                child: _buildDashboardContent(context, isWeb),
              ),
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: _buildDashboardContent(context, isWeb),
        ),
      );
    }
  }

  Widget _buildWebTopBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 16),
              const CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(
                    'https://ui-avatars.com/api/?name=Admin&background=4318D1&color=fff'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, bool isWeb) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        image: isWeb
            ? null
            : DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1551288049-bebda4e38f71?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2940&q=80',
          ),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.05),
            BlendMode.darken,
          ),
        ),
      ),
      child: Container(
        color: Colors.white.withOpacity(isWeb ? 1 : 0.95),
        padding: EdgeInsets.symmetric(
          horizontal: isWeb ? 32 : 16,
          vertical: isWeb ? 32 : 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isWeb) ...[
              const SizedBox(height: 16),
              const Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Welcome back! Here\'s what\'s happening today.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Stats Cards Grid
            _buildStatsGrid(isWeb),

            const SizedBox(height: 32),

            // Quick Actions
            _buildQuickActionsSection(isWeb),

            const SizedBox(height: 32),

            // Recent Activities
            _buildRecentActivitiesSection(isWeb),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(bool isWeb) {
    final stats = [
      {
        'title': 'Total Customers',
        'value': '1,248',
        'change': '+12%',
        'icon': Icons.people,
        'color': Colors.blue,
        'bgColor': Colors.blue[50],
      },
      {
        'title': 'Active Orders',
        'value': '56',
        'change': '+5%',
        'icon': Icons.shopping_cart,
        'color': Colors.green,
        'bgColor': Colors.green[50],
      },
      {
        'title': 'Revenue',
        'value': '\$24,580',
        'change': '+18%',
        'icon': Icons.attach_money,
        'color': Colors.purple,
        'bgColor': Colors.purple[50],
      },
      {
        'title': 'Pending Tasks',
        'value': '12',
        'change': '-3%',
        'icon': Icons.task,
        'color': Colors.orange,
        'bgColor': Colors.orange[50],
      },
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isWeb ? 4 : 2,
      crossAxisSpacing: isWeb ? 16 : 12,
      mainAxisSpacing: isWeb ? 16 : 12,
      childAspectRatio: isWeb ? 2 : 1.5,
      children: stats.map((stat) => _buildStatCard(stat, isWeb)).toList(),
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat, bool isWeb) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: stat['bgColor'] as Color?,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  stat['icon'] as IconData,
                  color: stat['color'] as Color,
                  size: isWeb ? 24 : 20,
                ),
              ),
              Text(
                stat['change'] as String,
                style: TextStyle(
                  color: (stat['change'] as String).startsWith('+')
                      ? Colors.green
                      : Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            stat['value'] as String,
            style: TextStyle(
              fontSize: isWeb ? 28 : 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          Text(
            stat['title'] as String,
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(bool isWeb) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: isWeb ? 20 : 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        _buildQuickActions(isWeb),
      ],
    );
  }

  Widget _buildQuickActions(bool isWeb) {
    final actions = [
      {
        'title': 'Add Customer',
        'icon': Icons.person_add,
        'color': const Color(0xFF4318D1),
      },
      {
        'title': 'View Reports',
        'icon': Icons.assessment,
        'color': Colors.green,
      },
      {
        'title': 'Send Message',
        'icon': Icons.message,
        'color': Colors.blue,
      },
      {
        'title': 'Schedule Meeting',
        'icon': Icons.calendar_today,
        'color': Colors.orange,
      },
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isWeb ? 4 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isWeb ? 1.2 : 1.5,
      children: actions.map((action) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (action['color'] as Color).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  action['icon'] as IconData,
                  color: action['color'] as Color,
                  size: isWeb ? 32 : 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                action['title'] as String,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isWeb ? 16 : 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentActivitiesSection(bool isWeb) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activities',
            style: TextStyle(
              fontSize: isWeb ? 20 : 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          _buildActivityList(),
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    final activities = [
      {
        'title': 'New customer registered',
        'description': 'John Doe added to the system',
        'time': '10 min ago',
        'icon': Icons.person_add,
        'color': Colors.green,
      },
      {
        'title': 'Order completed',
        'description': 'Order #ORD-2023-001 has been delivered',
        'time': '1 hour ago',
        'icon': Icons.check_circle,
        'color': Colors.blue,
      },
      {
        'title': 'Payment received',
        'description': '\$2,500 received from customer',
        'time': '2 hours ago',
        'icon': Icons.attach_money,
        'color': Colors.purple,
      },
      {
        'title': 'Meeting scheduled',
        'description': 'Client meeting at 3:00 PM tomorrow',
        'time': '5 hours ago',
        'icon': Icons.calendar_today,
        'color': Colors.orange,
      },
    ];

    return Column(
      children: activities.map((activity) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (activity['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  activity['icon'] as IconData,
                  color: activity['color'] as Color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity['title'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      activity['description'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                activity['time'] as String,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}