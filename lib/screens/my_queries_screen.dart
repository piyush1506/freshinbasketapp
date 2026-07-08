import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class MyQueriesScreen extends StatefulWidget {
  const MyQueriesScreen({super.key});

  @override
  State<MyQueriesScreen> createState() => _MyQueriesScreenState();
}

class _MyQueriesScreenState extends State<MyQueriesScreen> {
  late Future<List<dynamic>> _queries;

  @override
  void initState() {
    super.initState();
    _queries = _fetchQueries();
  }

  Future<List<dynamic>> _fetchQueries() async {
    return await ApiService.fetchContactQueries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Queries')),
      body: FutureBuilder<List<dynamic>>(
        future: _queries,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final queries = snapshot.data ?? [];
          if (queries.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.forum_outlined,
                      size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No queries yet',
                      style:
                          TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: queries.length,
            itemBuilder: (context, index) {
              final q = queries[index];
              final hasResponse =
                  q['response'] != null && q['response'].toString().isNotEmpty;
              String date = '';
              try {
                date = DateFormat('MMM dd, yyyy')
                    .format(DateTime.parse(q['created_at']).toLocal());
              } catch (_) {
                date = q['created_at'] ?? '';
              }
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(date,
                              style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: hasResponse
                                  ? Colors.green[50]
                                  : Colors.orange[50],
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: Text(
                              hasResponse ? 'Replied' : 'Awaiting reply',
                              style: TextStyle(
                                color: hasResponse
                                    ? Colors.green
                                    : Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(q['message'] ?? '',
                          style: const TextStyle(height: 1.4)),
                      if (hasResponse) ...[
                        const Divider(height: 20),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text('Response:',
                                  style: TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                      fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(q['response'] ?? '',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
