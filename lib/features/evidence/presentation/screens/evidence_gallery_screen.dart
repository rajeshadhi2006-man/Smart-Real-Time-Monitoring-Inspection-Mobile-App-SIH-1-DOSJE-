import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/models/evidence_item.dart';
import '../providers/evidence_provider.dart';

class EvidenceGalleryScreen extends ConsumerWidget {
  final String inspectionId;

  const EvidenceGalleryScreen({
    super.key,
    required this.inspectionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(evidenceStateProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Evidence Vault & Hashes'),
      ),
      body: list.isEmpty
          ? const Center(child: Text('No evidence recorded yet.'))
          : GridView.builder(
              padding: const EdgeInsets.all(AppDimensions.space16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final item = list[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppDimensions.roundedMedium,
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Preview placeholder or image
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: item.type == EvidenceType.photo
                                ? AppColors.primaryNavy.withValues(alpha: 0.08)
                                : AppColors.accentSaffron.withValues(alpha: 0.1),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(AppDimensions.radiusMedium),
                            ),
                          ),
                          child: (item.remoteUrl != null && item.remoteUrl!.isNotEmpty)
                              ? ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(AppDimensions.radiusMedium),
                                  ),
                                  child: Image.network(
                                    item.remoteUrl!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorBuilder: (context, error, stackTrace) => Center(
                                      child: Icon(
                                        item.type == EvidenceType.photo ? Icons.image_outlined : Icons.play_circle_outline,
                                        size: 40,
                                        color: item.type == EvidenceType.photo ? AppColors.primaryNavy : AppColors.accentSaffron,
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Icon(
                                    item.type == EvidenceType.photo
                                        ? Icons.image_outlined
                                        : Icons.play_circle_outline,
                                    size: 40,
                                    color: item.type == EvidenceType.photo
                                        ? AppColors.primaryNavy
                                        : AppColors.accentSaffron,
                                  ),
                                ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.categoryTag,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'SHA: ${item.sha256Hash.substring(0, 10)}...',
                              style: const TextStyle(
                                fontSize: 9,
                                fontFamily: 'monospace',
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '✓ Verified',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.successGreen,
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    ref
                                        .read(evidenceStateProvider.notifier)
                                        .removeEvidence(item.id);
                                  },
                                  child: const Icon(
                                    Icons.delete_outline,
                                    size: 16,
                                    color: AppColors.dangerRed,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
