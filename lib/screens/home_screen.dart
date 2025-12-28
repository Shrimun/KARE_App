import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      backgroundColor: const Color(0xFF252525),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Icon
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[800],
                child: Icon(Icons.person, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 40),
              
              // Welcome Circle with gradient
              Center(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    color: const Color(0xFF252525),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: -9,
                        offset: const Offset(-2, -6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Hi, ${user?.name ?? 'Jarvis'} 👋',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap to chat',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 50),
              
              // Explore Section
              const Text(
                'Explore',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              
              // Grid of Cards
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 15,
                  crossAxisSpacing: 20,
                  childAspectRatio: 153 / 133,
                  children: [
                    _ExploreCard(
                      title: 'Rules and\nRegulations',
                      color: const Color(0xFF3F967F),
                      icon: Icons.book_outlined,
                      onTap: () => Navigator.of(context).pushNamed('/ask'),
                    ),
                    _ExploreCard(
                      title: 'Mark\nCalculator',
                      color: const Color(0xFF7F5AB1),
                      icon: Icons.calculate_outlined,
                      onTap: () => Navigator.of(context).pushNamed('/ask'),
                    ),
                    _ExploreCard(
                      title: 'CGPA\nCalculator',
                      color: const Color(0xFFB55B61),
                      icon: Icons.assessment_outlined,
                      onTap: () => Navigator.of(context).pushNamed('/ask'),
                    ),
                    _ExploreCard(
                      title: 'Credits\nCalculator',
                      color: const Color(0xFFB4B65D),
                      icon: Icons.school_outlined,
                      onTap: () => Navigator.of(context).pushNamed('/ask'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _ExploreCard({
    required this.title,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: Icon(icon, size: 18, color: Colors.transparent),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
