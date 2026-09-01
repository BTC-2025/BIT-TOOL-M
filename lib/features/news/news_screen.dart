import 'package:flutter/material.dart';
import '../../core/widgets/neumorphic_widgets.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  void _showNewsDetail(BuildContext context, String title, String category, String fullContent, IconData icon, Color color) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return NeumorphicCard(
              borderRadius: 24,
              padding: const EdgeInsets.all(24),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.toUpperCase(),
                            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const Text('Detailed Report', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, height: 1.2),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  Text(
                    fullContent,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 32),
                  NeumorphicCard(
                    borderRadius: 16,
                    color: Theme.of(context).primaryColor.withOpacity(0.05),
                    child: const Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.link),
                          title: Text('Related Documentation', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Review official BNX whitepapers'),
                        ),
                        ListTile(
                          leading: Icon(Icons.share),
                          title: Text('Share with Team', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Distribute security advisory'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  NeumorphicButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back to Feed', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text(
            'Hot News & Updates',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Latest from BNX Ecosystem and Technology World',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 24),

          _buildNewsCard(
            context,
            'BNX Mail introduces AI-powered Smart Replies',
            'Technology',
            'BNX Mail has launched a new feature that uses advanced language models to suggest context-aware replies to your emails.',
            'The new AI engine, built on the BNX Neural Network (BNN), analyzes incoming email threads to generate three distinct response options. This feature aims to save users up to 30% of their daily communication time. The model runs locally on edge nodes to maintain strict user privacy and zero-knowledge architecture. Updates are rolling out to all premium accounts starting next week.',
            '2 hours ago',
            Icons.auto_awesome,
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildNewsCard(
            context,
            'B2Auth strengthens Multi-Factor Authentication',
            'Security',
            'A new update to B2Auth brings hardware security key support and enhanced biometric verification for all enterprise users.',
            'As part of the BNX "Zero Trust" initiative, B2Auth has now integrated FIDO2 support. Users can now utilize hardware keys like Yubico or Nitrokey for an extra layer of protection. Additionally, the system now features "Behavioral Biometrics" which can detect suspicious usage patterns in real-time, effectively blocking automated bot attacks before they reach sensitive data layers.',
            '5 hours ago',
            Icons.security,
            Colors.green,
          ),
          const SizedBox(height: 16),
          _buildNewsCard(
            context,
            'ClicksBusiness launches globally in 20+ countries',
            'Business',
            'The ClicksBusiness platform is now available in more regions, offering streamlined payment and inventory management solutions.',
            'After a successful pilot program in Southeast Asia, ClicksBusiness is expanding its footprint to Europe and North America. The platform integrates directly with BNX Financial Services to provide instant cross-border settlements with 0% transaction fees for internal ecosystem transfers. Business owners can now access global inventory tracking tools directly from their unified dashboard.',
            '1 day ago',
            Icons.business_center,
            Colors.orange,
          ),
          const SizedBox(height: 16),
          _buildNewsCard(
            context,
            'Critical Security Update for BNX Lens',
            'Critical',
            'All users are advised to update their BNX Lens application to the latest version to patch a high-severity vulnerability.',
            'Security researchers at BNX Labs identified a memory corruption vulnerability in the image processing engine of BNX Lens v2.4. This vulnerability could theoretically allow remote code execution if a specially crafted image is scanned. Version 2.5 has been released immediately to mitigate this risk. All cloud-synchronized devices have been auto-patched, but manual offline installations must be updated manually.',
            '2 days ago',
            Icons.warning_amber_rounded,
            Colors.red,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildNewsCard(
    BuildContext context,
    String title,
    String category,
    String snippet,
    String fullContent,
    String time,
    IconData icon,
    Color color,
  ) {
    return NeumorphicCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  category.toUpperCase(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ),
              const Spacer(),
              Text(
                time,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            snippet,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _showNewsDetail(context, title, category, fullContent, icon, color),
                child: const Row(
                  children: [
                    Text('Read More', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
