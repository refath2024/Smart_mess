import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'chat_screen.dart'; // Add at the top of help_screen.dart

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: const Color(0xFF002B5B),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("FAQs", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildFaqTile("How do I update my meal info?", "Go to Meal IN/OUT tab and select your current meal status."),
          _buildFaqTile("How can I pay my mess bill?", "Navigate to the Billing tab and click on Pay Bill."),
          _buildFaqTile("Can I change my menu preference?", "Yes, in the Menu Set screen, choose your preferred item."),
          const Divider(height: 32),

          const Text("Guides & Tutorials", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildGuideTile("💡 Getting Started Guide", "Tap to learn how to use the app."),
          _buildGuideTile("📝 How to submit feedback", "Learn how to suggest features."),
          const Divider(height: 32),

          const Text("Contact Us", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildContactTile(
            icon: Icons.phone,
            title: "Call Us",
            subtitle: "+880 1234-567890",
            onTap: () => _launchPhone("+8801234567890"),
          ),
          _buildContactTile(
            icon: Icons.email,
            title: "Email",
            subtitle: "support@smartmess.com",
            onTap: () => _launchEmail("support@smartmess.com"),
          ),
          _buildContactTile(
            icon: Icons.web,
            title: "Visit Website",
            subtitle: "https://smartmess.com",
            onTap: () => _launchWeb("https://smartmess.com"),
          ),
          _buildContactTile(
            icon: Icons.location_on,
            title: "Office Address",
            subtitle: "Smart Mess HQ, Cantonment, Dhaka",
          ),
          const Divider(height: 32),

          const Text("Need More Help?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListTile(
  leading: const Icon(Icons.chat),
  title: const Text("Talk to AI Assistant"),
  subtitle: const Text("Instant help through smart chatbot"),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatScreen()),
    );
  },
),
          const Divider(height: 32),

          const Text("Was this page helpful?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Thank you for your feedback!")),
                  );
                },
                icon: const Icon(Icons.thumb_up),
                label: const Text("Yes"),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("We'll try to improve.")),
                  );
                },
                icon: const Icon(Icons.thumb_down),
                label: const Text("No"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFaqTile(String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600)),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(answer),
        ),
      ],
    );
  }

  Widget _buildGuideTile(String title, String subtitle) {
    return ListTile(
      leading: const Icon(Icons.book),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () {
        // Could navigate to a guide screen or PDF
      },
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }

  void _launchPhone(String phoneNumber) async {
    final Uri url = Uri.parse("tel:$phoneNumber");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _launchEmail(String emailAddress) async {
    final Uri url = Uri.parse("mailto:$emailAddress");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _launchWeb(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}
