// profile_stats.dart
import 'package:flutter/material.dart';

class ProfileStats extends StatelessWidget {
  const ProfileStats({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.2,
            colors: [
              Colors.purple.withValues(alpha: 0.4),
              const Color(0xFF1a1a1a),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 900;
                final maxWidth = isDesktop ? 800.0 : constraints.maxWidth * 0.9;

                return SingleChildScrollView(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 0 : 20,
                      vertical: 40,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'My Stats',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 40),
                        _buildTopStats(),
                        const SizedBox(height: 40),
                        _buildDateSelector(),
                        const SizedBox(height: 30),
                        _buildCardsGrid(isDesktop),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StatItem(icon: Icons.favorite, value: '3.1 mill.'),
        const SizedBox(width: 50),
        _StatItem(icon: Icons.chat_bubble, value: '55.3 mil'),
        const SizedBox(width: 50),
        _StatItem(icon: Icons.reply, value: '41.5 mil'),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF4a4a4a),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Últimos 30 días',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey[400],
                size: 18,
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Text(
          '17/1/2025 to 17/1/2025',
          style: TextStyle(color: Colors.grey[400], fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildCardsGrid(bool isDesktop) {
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildOverviewCard()),
          const SizedBox(width: 24),
          Expanded(child: _buildFollowersCard()),
        ],
      );
    } else {
      return Column(
        children: [
          _buildOverviewCard(),
          const SizedBox(height: 24),
          _buildFollowersCard(),
        ],
      );
    }
  }

  Widget _buildOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2a2a2a),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insert_chart_outlined,
                color: Colors.grey[300],
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Overview',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildMetricRow('Likes:', '3,100,000'),
          const SizedBox(height: 12),
          _buildMetricRow('Comments:', '55,300'),
          const SizedBox(height: 12),
          _buildMetricRow('Shared:', '41,500'),
        ],
      ),
    );
  }

  Widget _buildFollowersCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2a2a2a),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people_outline, color: Colors.grey[300], size: 18),
              const SizedBox(width: 8),
              const Text(
                'Followers',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildPlatformRow('Migozz', '60.2k'),
          const SizedBox(height: 12),
          _buildPlatformRow('Tiktok', '40.1k'),
          const SizedBox(height: 12),
          _buildPlatformRow('Instagram', '90.2k'),
          const SizedBox(height: 12),
          _buildPlatformRow('All', '130.3k'),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey[300], fontSize: 13)),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildPlatformRow(String platform, String followers) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.circle, color: Colors.grey[600], size: 10),
        ),
        const SizedBox(width: 10),
        Text(
          platform,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
        const Spacer(),
        Text(
          followers,
          style: TextStyle(color: Colors.grey[400], fontSize: 13),
        ),
        const SizedBox(width: 8),
        Icon(Icons.chevron_right, color: Colors.grey[600], size: 18),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;

  const _StatItem({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
