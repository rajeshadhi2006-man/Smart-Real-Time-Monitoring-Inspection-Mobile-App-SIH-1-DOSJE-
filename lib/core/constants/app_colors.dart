import 'package:flutter/material.dart';

/// Executive Indian National Digital Architecture Design Tokens
/// Official Government of India & MoSJE Flagship Aesthetic
class AppColors {
  const AppColors._();

  // National Sovereign & Tricolor Tokens
  static const Color tricolorSaffron = Color(0xFFFF9933);
  static const Color tricolorWhite = Color(0xFFFFFFFF);
  static const Color tricolorGreen = Color(0xFF138808);
  static const Color tricolorNavy = Color(0xFF000080); // Ashoka Chakra Blue

  // Primary Government & Enterprise Identity
  static const Color primaryNavy = Color(0xFF0A192F); // Executive Ashoka Navy
  static const Color primaryBlue = Color(0xFF0D254C); // Deep Royal Navy
  static const Color primaryAshoka = Color(0xFF0D3B66);
  static const Color primaryLight = Color(0xFFEFF6FF);
  static const Color primaryMuted = Color(0xFF334E68);

  // Surface & Canvas (Clean, Legible Professional Dark & Light Tokens)
  static const Color backgroundDark = Color(0xFF0B1424);
  static const Color surfaceDark = Color(0xFF111C33);
  static const Color cardDark = Color(0xFF162544);
  static const Color borderDark = Color(0xFF24385E);

  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Status & Telemetry Indicators (Government-Grade Semantic Colors)
  static const Color statusGreen = Color(0xFF10B981); // INSIDE / VERIFIED
  static const Color statusAmber = Color(0xFFF59E0B); // VERIFYING / PENDING
  static const Color statusRed = Color(0xFFEF4444);   // OUTSIDE / UNAUTHORIZED / FAILED
  static const Color statusBlue = Color(0xFF3B82F6);  // CONNECTING / ACTIVE
  static const Color statusGrey = Color(0xFF64748B);  // OFFLINE

  // Legacy Aliases for Backwards Compatibility
  static const Color dangerRed = statusRed;
  static const Color dangerLight = Color(0xFF7F1D1D);
  static const Color successGreen = statusGreen;
  static const Color successLight = Color(0xFF064E3B);
  static const Color warningAmber = statusAmber;
  static const Color warningLight = Color(0xFF78350F);
  static const Color infoBlue = statusBlue;
  static const Color infoLight = Color(0xFF0C4A6E);

  static const Color cardBackground = cardDark;
  static const Color cyberBorder = borderDark;
  static const Color neonCyan = statusBlue;
  static const Color neonEmerald = statusGreen;
  static const Color neonAmber = statusAmber;
  static const Color neonPurple = Color(0xFFA855F7);

  static const Color goldAccent = tricolorSaffron;
  static const Color solarSaffron = tricolorSaffron;
  static const Color accentTeal = Color(0xFF0D9488);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentSaffron = tricolorSaffron;

  // Typography Tokens
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textMutedLight = Color(0xFF94A3B8);

  // Gradients for Government Cards & Headers
  static const LinearGradient govtHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0A192F),
      Color(0xFF0D254C),
      Color(0xFF1E3A8A),
    ],
  );

  static const LinearGradient heroNavyGradient = govtHeaderGradient;
  static const LinearGradient solarSaffronGradient = govtHeaderGradient;
  static const LinearGradient cyberCyanGradient = govtHeaderGradient;

  static const LinearGradient cardHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF111C33),
      Color(0xFF162544),
    ],
  );

  static Color statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'INSIDE':
      case 'VERIFIED':
      case 'CONNECTED':
      case 'ONLINE':
      case 'MATCH':
      case 'PRESENT':
      case 'ACCEPTED':
      case 'COMPLETED':
      case 'SUBMITTED':
        return statusGreen;
      case 'VERIFYING':
      case 'PENDING':
      case 'CALLING':
      case 'RINGING':
      case 'RECONNECTING':
      case 'IN PROGRESS':
      case 'UNDER REVIEW':
        return statusAmber;
      case 'OUTSIDE':
      case 'UNAUTHORIZED':
      case 'FAILED':
      case 'MISMATCH':
      case 'REJECTED':
      case 'OFFLINE':
      case 'HIGH RISK':
      case 'CANCELLED':
        return statusRed;
      default:
        return statusGrey;
    }
  }

  static Color statusBackgroundColor(String status) {
    switch (status.toUpperCase()) {
      case 'INSIDE':
      case 'VERIFIED':
      case 'CONNECTED':
      case 'ONLINE':
      case 'MATCH':
      case 'PRESENT':
      case 'ACCEPTED':
      case 'COMPLETED':
      case 'SUBMITTED':
        return successLight;
      case 'VERIFYING':
      case 'PENDING':
      case 'CALLING':
      case 'RINGING':
      case 'RECONNECTING':
      case 'IN PROGRESS':
      case 'UNDER REVIEW':
        return warningLight;
      case 'OUTSIDE':
      case 'UNAUTHORIZED':
      case 'FAILED':
      case 'MISMATCH':
      case 'REJECTED':
      case 'OFFLINE':
      case 'HIGH RISK':
      case 'CANCELLED':
        return dangerLight;
      default:
        return surfaceDark;
    }
  }
}
