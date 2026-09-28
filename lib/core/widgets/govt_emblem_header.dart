import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Sovereign Government of India Emblem & Ministry Banner
/// Renders the National Emblem Lion crest motif, bilingual titles,
/// and official tricolor security ribbon.
class GovtEmblemHeader extends StatelessWidget {
  final bool compact;
  final bool showMinistry;
  final String? subtitle;
  final Color? backgroundColor;

  const GovtEmblemHeader({
    super.key,
    this.compact = false,
    this.showMinistry = true,
    this.subtitle,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primaryNavy,
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: compact ? 8 : 12,
            ),
            child: Row(
              children: [
                // National Ashoka Stambha / Sovereign Crest Badge
                Container(
                  width: compact ? 38 : 46,
                  height: compact ? 38 : 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFDE68A),
                        Color(0xFFD97706),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFFFEF3C7),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.shield_rounded,
                      color: AppColors.primaryNavy,
                      size: compact ? 22 : 26,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Bilingual Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Satyameva Jayate + Govt of India
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.tricolorSaffron.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppColors.tricolorSaffron.withValues(alpha: 0.4),
                                width: 0.8,
                              ),
                            ),
                            child: const Text(
                              "सत्यमेव जयते",
                              style: TextStyle(
                                color: Color(0xFFFDE68A),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Flexible(
                            child: Text(
                              "भारत सरकार • GOVT. OF INDIA",
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),

                      // Ministry Name
                      if (showMinistry)
                        Text(
                          "सामाजिक न्याय एवं अधिकारिता मंत्रालय",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: compact ? 11 : 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      Text(
                        subtitle ?? "Ministry of Social Justice and Empowerment",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF94A3B8),
                          fontSize: compact ? 9.5 : 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Security / SIH Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.statusGreen.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.statusGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        "NIC SECURE",
                        style: TextStyle(
                          color: AppColors.statusGreen,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // National Tricolor Micro Accent Ribbon
          Container(
            height: 3,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppColors.tricolorRibbonGradient,
            ),
          ),
        ],
      ),
    );
  }
}
