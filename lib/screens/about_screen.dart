import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Us')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFF164431).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart,
                      size: 60, color: Color(0xFF164431)),
                  SizedBox(height: 12),
                  Text('Freshinbasket',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF164431))),
                  Text('Farm Fresh Delivered',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Our Story',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text(
            'Freshinbasket brings the freshest vegetables and fruits directly from farms to your doorstep. '
            'We partner with local farmers to ensure you get the highest quality produce at the best prices.',
            style: TextStyle(color: Colors.grey, height: 1.6),
          ),
          const SizedBox(height: 24),
          const Text('Core Values',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _valueCard(
            Icons.eco,
            'Farm Fresh',
            'Directly sourced from farms, harvested at peak ripeness.',
            const Color(0xFFE8F5E9),
          ),
          const SizedBox(height: 12),
          _valueCard(
            Icons.people,
            'Community First',
            'Supporting local farmers and building a sustainable food system.',
            const Color(0xFFE3F2FD),
          ),
          const SizedBox(height: 12),
          _valueCard(
            Icons.star,
            'Unmatched Quality',
            'Every product is handpicked and quality-checked before delivery.',
            const Color(0xFFFFF3E0),
          ),
          const SizedBox(height: 12),
          _valueCard(
            Icons.local_shipping,
            'Farm to Door',
            'Delivered fresh within 24 hours of harvest.',
            const Color(0xFFF3E5F5),
          ),
        ],
      ),
    );
  }

  Widget _valueCard(
      IconData icon, String title, String desc, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 36, color: const Color(0xFF164431)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text(desc,
                    style: TextStyle(color: Colors.grey[700], fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
