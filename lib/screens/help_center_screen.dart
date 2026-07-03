import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/contact_query.dart';
import '../providers/auth_provider.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  late Future<List<ContactQuery>> _queriesFuture;

  @override
  void initState() {
    super.initState();
    _queriesFuture = ApiService.fetchContactQueriesModel();
  }

  void _refreshQueries() {
    setState(() {
      _queriesFuture = ApiService.fetchContactQueriesModel();
    });
  }

  String _formatDate(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy • hh:mm a').format(parsed);
    } catch (_) {
      return dateStr;
    }
  }

  void _openSubmitQuerySheet() {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final messageController = TextEditingController();
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Submit a Query',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF222222),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'How can we help you today? Please describe your query in detail.',
                style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Enter your message...',
                  hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFEBEBEB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF164431), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          final msg = messageController.text.trim();
                          if (msg.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a message'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          setSheetState(() => submitting = true);
                          try {
                            final email = user.email.trim().isNotEmpty
                                ? user.email.trim()
                                : '${user.username.trim().replaceAll(' ', '_')}@greenmart.com';
                            await ApiService.submitContact(
                              name: user.username,
                              email: email,
                              message: msg,
                            );
                            if (mounted) {
                              Navigator.pop(ctx);
                              _refreshQueries();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Query submitted successfully!'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              setSheetState(() => submitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to submit: $e'),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF164431),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Submit Ticket',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F5),
      appBar: AppBar(
        title: const Text(
          'Help Center',
          style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF222222)),
        ),
        backgroundColor: const Color(0xFFF7F8F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF222222), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<ContactQuery>>(
        future: _queriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF164431)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 56, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    const Text(
                      'Failed to load queries',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF222222)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _refreshQueries,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF164431),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final queries = snapshot.data ?? [];

          if (queries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.support_agent, size: 72, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'No queries submitted yet',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF222222)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Submit a ticket if you have any questions or issues with your order.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _openSubmitQuerySheet,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Submit Query'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF164431),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _refreshQueries(),
            color: const Color(0xFF164431),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: queries.length,
              itemBuilder: (context, index) {
                final query = queries[index];
                final isResolved = query.response != null && query.response!.isNotEmpty;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ExpansionTile(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                    ),
                    collapsedShape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                    ),
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ticket #${query.id}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF222222),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isResolved
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isResolved ? 'Resolved' : 'Pending',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isResolved
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFEF6C00),
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        _formatDate(query.createdAt),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(),
                            const SizedBox(height: 8),
                            const Text(
                              'Your Query:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF666666),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              query.message,
                              style: const TextStyle(fontSize: 14, color: Color(0xFF222222)),
                            ),
                            if (isResolved) ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F8F5),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFE8F5E9)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.rate_review, size: 16, color: Color(0xFF2E7D32)),
                                        SizedBox(width: 6),
                                        Text(
                                          'Admin Response:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2E7D32),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      query.response!,
                                      style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
                                    ),
                                    if (query.respondedAt != null) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        _formatDate(query.respondedAt!),
                                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openSubmitQuerySheet,
        backgroundColor: const Color(0xFF164431),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_comment),
      ),
    );
  }
}
