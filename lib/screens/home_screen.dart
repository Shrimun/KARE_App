import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final size = MediaQuery.of(context).size;
    final isSmallDevice = size.width < 360;
    final padding = size.width * 0.05;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Icon
              GestureDetector(
                onTap: () => Navigator.of(context).pushNamed('/profile'),
                child: CircleAvatar(
                  radius: isSmallDevice ? 18 : 20,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  child: Icon(Icons.person, color: Colors.white, size: isSmallDevice ? 20 : 24),
                ),
              ),
              SizedBox(height: size.height * 0.03),
              
              // Welcome Circle with glass effect
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pushNamed('/ask'),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(size.width * 0.3),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        width: size.width * 0.6,
                        height: size.width * 0.6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.35),
                              Theme.of(context).colorScheme.primary.withOpacity(0.55),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.6),
                            width: 1.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 25,
                              spreadRadius: -8,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Hi, ${user?.name ?? 'Jarvis'} 👋',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSmallDevice ? 14 : 16,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            SizedBox(height: isSmallDevice ? 4 : 8),
                            Text(
                              'Tap to chat',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSmallDevice ? 18 : 20,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.08),

              // Explore Section
              Text(
                'Explore',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: isSmallDevice ? 20 : 24,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: size.height * 0.02),
              
              // Grid of Cards (content-sized to avoid large empty space)
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: size.width * 0.04,
                crossAxisSpacing: size.width * 0.05,
                childAspectRatio: isSmallDevice ? 1.0 : 1.15,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _ExploreCard(
                    title: 'Rules and\nRegulations',
                    color: Theme.of(context).colorScheme.primary,
                    icon: Icons.book_outlined,
                    onTap: () => Navigator.of(context).pushNamed('/rules'),
                  ),
                  _ExploreCard(
                    title: 'SIS Login',
                    color: Theme.of(context).colorScheme.secondary,
                    icon: Icons.language,
                    onTap: () async {
                      final url = Uri.parse('https://sis.kalasalingam.ac.in/login');
                      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Could not launch SIS website')),
                          );
                        }
                      }
                    },
                  ),
                ],
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
    final size = MediaQuery.of(context).size;
    final isSmallDevice = size.width < 360;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(isSmallDevice ? 15 : 20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: EdgeInsets.all(isSmallDevice ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: isSmallDevice ? 24 : 28,
                color: Colors.white,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallDevice ? 12 : 14,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
