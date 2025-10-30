import 'package:flutter/material.dart';
import '../../models/expert.dart';
import 'widgets/expert_card.dart';
import 'expert_detail_page.dart';
import '../appointment/my_appointments_page.dart';

class ExpertListPage extends StatefulWidget {
  const ExpertListPage({super.key});

  @override
  State<ExpertListPage> createState() => _ExpertListPageState();
}

class _ExpertListPageState extends State<ExpertListPage> {
  List<Expert> _experts = [];
  List<Expert> _filteredExperts = [];
  bool _isLoading = true;
  String? _selectedSpecialization;

  final List<String> _specializations = [
    'All',
    'Anxiety',
    'Depression',
    'Stress',
    'Sleep',
    'Relationships',
  ];

  @override
  void initState() {
    super.initState();
    _loadExperts();
  }

  Future<void> _loadExperts() async {
    setState(() => _isLoading = true);

    try {
      final experts = await Expert.getAllExperts();
      setState(() {
        _experts = experts;
        _filteredExperts = experts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading experts: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterExperts(String? specialization) {
    setState(() {
      _selectedSpecialization = specialization;
      if (specialization == null || specialization == 'All') {
        _filteredExperts = _experts;
      } else {
        _filteredExperts = _experts
            .where((e) => e.specialization == specialization)
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Find an Expert',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false, // Remove back button
        actions: [
          // My Appointments button
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.calendar_month_outlined,
                  color: Color(0xFF4CAF50),
                  size: 28,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyAppointmentsPage(),
                    ),
                  );
                },
                tooltip: 'My Appointments',
              ),
              // Optional: Badge for pending appointments count
              // Positioned(
              //   right: 8,
              //   top: 8,
              //   child: Container(
              //     padding: const EdgeInsets.all(4),
              //     decoration: const BoxDecoration(
              //       color: Colors.red,
              //       shape: BoxShape.circle,
              //     ),
              //     constraints: const BoxConstraints(
              //       minWidth: 16,
              //       minHeight: 16,
              //     ),
              //     child: const Text(
              //       '2',
              //       style: TextStyle(
              //         color: Colors.white,
              //         fontSize: 10,
              //         fontWeight: FontWeight.w700,
              //       ),
              //       textAlign: TextAlign.center,
              //     ),
              //   ),
              // ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Specialization Filter
          Container(
            height: 60,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _specializations.length,
              itemBuilder: (context, index) {
                final spec = _specializations[index];
                final isSelected = _selectedSpecialization == spec ||
                    (_selectedSpecialization == null && spec == 'All');

                return GestureDetector(
                  onTap: () => _filterExperts(spec == 'All' ? null : spec),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF4CAF50)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        spec,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Expert Count
          if (!_isLoading)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.grey.shade50,
              child: Text(
                '${_filteredExperts.length} ${_filteredExperts.length == 1 ? 'expert' : 'experts'} available',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ),

          // Expert List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF4CAF50),
                    ),
                  )
                : _filteredExperts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 80,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No experts found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try selecting a different specialization',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadExperts,
                        color: const Color(0xFF4CAF50),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredExperts.length,
                          itemBuilder: (context, index) {
                            final expert = _filteredExperts[index];
                            return ExpertCard(
                              expert: expert,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ExpertDetailPage(expert: expert),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
