import 'package:flutter/material.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';

class EventsScreen extends StatelessWidget {
  final UserDTO user;

  const EventsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final String name = user.displayName.isNotEmpty
        ? user.displayName
        : user.username;
    final String username = user.username.startsWith('@')
        ? user.username
        : '@${user.username}';

    // Build the bio strings
    final List<String> bioLines = [];
    if (user.bio != null && user.bio!.isNotEmpty) {
      bioLines.add(user.bio!);
    }
    if (user.contactEmail != null && user.contactEmail!.isNotEmpty) {
      bioLines.add(user.contactEmail!);
    }
    final String combinedBio = bioLines.join('\n');

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Content
          SingleChildScrollView(
            child: Column(
              children: [
                // Header (Image + Gradient)
                Stack(
                  children: [
                    // Main Image
                    if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                      Image.network(
                        user.avatarUrl!,
                        width: double.infinity,
                        height: size.height * 0.45,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            height: size.height * 0.45,
                            color: Colors.grey[800],
                            child: const Icon(
                              Icons.person,
                              size: 80,
                              color: Colors.white54,
                            ),
                          );
                        },
                      )
                    else
                      Container(
                        width: double.infinity,
                        height: size.height * 0.45,
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.person,
                          size: 80,
                          color: Colors.white54,
                        ),
                      ),

                    // Gradient overlay to fade to black
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.transparent,
                              Colors.black87,
                              Colors.black,
                            ],
                            stops: [0.0, 0.4, 0.8, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // User Info
                    Positioned(
                      bottom: 0,
                      left: 20,
                      right: 20,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(blurRadius: 10, color: Colors.black),
                              ],
                            ),
                          ),
                          Text(
                            username,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          if (combinedBio.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                combinedBio,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Events List (Mock Data)
                _buildEventItem(
                  month: 'May',
                  day: '1',
                  title: 'Highland',
                  details: 'Fri, 8pm | Yaamava\'Theater',
                ),
                _buildEventItem(
                  month: 'May',
                  day: '3',
                  title: 'Highland',
                  details: 'Sun, 9pm | Yaamava\'Theater',
                ),
                _buildEventItem(
                  month: 'May',
                  day: '5',
                  title: 'Highland',
                  details: 'Tue, 9pm | Yaamava\'Theater',
                ),
                _buildEventItem(
                  month: 'May',
                  day: '7',
                  title: 'Morrison',
                  details: 'Thu, 7pm | Red Rocks Amphitheatre',
                ),
                _buildEventItem(
                  month: 'May',
                  day: '9',
                  title: 'Rosemont',
                  details: 'Sat, 8pm | Allstate Arena',
                ),

                const SizedBox(height: 30),

                // View All Events Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFECA376), Color(0xFFA140B4)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'View all events',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),

          // Back Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem({
    required String month,
    required String day,
    required String title,
    required String details,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  month,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  day,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  details,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFECA376), Color(0xFFA140B4)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Buy tickets',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
