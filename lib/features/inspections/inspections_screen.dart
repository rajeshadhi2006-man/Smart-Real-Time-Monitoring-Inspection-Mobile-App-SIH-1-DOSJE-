import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/govt_emblem_header.dart';
import '../../core/widgets/sovereign_colorful_background.dart';
import '../../models/inspection_model.dart';
import '../../providers/app_providers.dart';

class InspectionsScreen extends ConsumerStatefulWidget {
  const InspectionsScreen({super.key});

  @override
  ConsumerState<InspectionsScreen> createState() => _InspectionsScreenState();
}

class _InspectionsScreenState extends ConsumerState<InspectionsScreen> {
  String _selectedFilter = 'ALL';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final inspectionsAsync = ref.watch(inspectionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF040A15),
      body: SovereignColorfulBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Official Sovereign Header
              const GovtEmblemHeader(
                compact: true,
                subtitle: "National Field Audit Ledger & Immutable Records",
                backgroundColor: Color(0xCC07152B),
              ),

              // Search Bar & Filter Strip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xBF081932),
                  border: Border(
                    bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                ),
                child: Column(
                  children: [
                    // Search Input
                    TextField(
                      onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                      style: const TextStyle(color: Colors.white, fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: "Search by inspection code, facility, scheme...",
                        hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5),
                        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF38BDF8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        filled: true,
                        fillColor: const Color(0x59040D1A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0x3338BDF8)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0x2E38BDF8)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip("ALL", "All Audits"),
                          const SizedBox(width: 8),
                          _buildFilterChip("COMPLETED", "Completed"),
                          const SizedBox(width: 8),
                          _buildFilterChip("PENDING", "Pending Action"),
                          const SizedBox(width: 8),
                          _buildFilterChip("SURPRISE", "Surprise Checks"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Records List
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.tricolorSaffron,
                  backgroundColor: const Color(0xFF0A192F),
                  onRefresh: () async {
                    ref.invalidate(inspectionsProvider);
                  },
                  child: inspectionsAsync.when(
                    data: (inspections) {
                      final filtered = inspections.where((item) {
                        final matchesFilter = _selectedFilter == 'ALL' ||
                            (_selectedFilter == 'COMPLETED' && item.status == 'COMPLETED') ||
                            (_selectedFilter == 'PENDING' && (item.status == 'PENDING' || item.status == 'ASSIGNED')) ||
                            (_selectedFilter == 'SURPRISE' && item.inspectionType.toUpperCase().contains('SURPRISE'));

                        final matchesSearch = _searchQuery.isEmpty ||
                            item.inspectionCode.toLowerCase().contains(_searchQuery) ||
                            item.projectName.toLowerCase().contains(_searchQuery) ||
                            item.ngoInstitute.toLowerCase().contains(_searchQuery);

                        return matchesFilter && matchesSearch;
                      }).toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0x3338BDF8)),
                                  ),
                                  child: const Icon(Icons.assignment_turned_in_outlined, size: 36, color: Color(0xFF38BDF8)),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "No Audit Records Found",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  "Inspection reports submitted by officers will appear in this ledger.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return _buildInspectionTile(context, filtered[index]);
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: AppColors.tricolorSaffron)),
                    error: (e, stack) => Center(child: Text("Error fetching audits: $e", style: const TextStyle(color: Color(0xFF94A3B8)))),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = key),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6.5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E3A5F) : const Color(0x400A1A2F),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF38BDF8) : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFFFDE68A) : const Color(0xFF94A3B8),
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildInspectionTile(BuildContext context, InspectionModel item) {
    final isCompleted = item.status == 'COMPLETED';
    final statusColor = isCompleted ? AppColors.statusGreen : AppColors.tricolorSaffron;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xD90A1B33),
            Color(0xBF071324),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x3338BDF8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Code & Status Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_outlined, size: 16, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 6),
                    Text(
                      item.inspectionCode,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13.5,
                        fontFamily: 'monospace',
                        color: Color(0xFF38BDF8),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withValues(alpha: 0.5), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Text(
                        item.status.toUpperCase(),
                        style: TextStyle(color: statusColor, fontSize: 10.5, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Project / Facility
            Text(
              item.projectName,
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            const SizedBox(height: 3),
            Text(
              "Facility: ${item.ngoInstitute}",
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),

            // Meta Footer with SHA-256 pill and Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, size: 13, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      item.createdAt.length >= 10 ? item.createdAt.substring(0, 10) : item.createdAt,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0x66040D1A),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: const Color(0x3338BDF8)),
                  ),
                  child: Text(
                    "SHA-256: ${item.inspectionCode.hashCode.abs().toRadixString(16).padLeft(8, '0').toUpperCase()}",
                    style: const TextStyle(fontSize: 9.5, color: Color(0xFF38BDF8), fontFamily: 'monospace', fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
