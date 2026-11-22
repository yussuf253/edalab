import '/pro/l10n/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class DoctorTelemedicineScreen extends StatelessWidget {
  const DoctorTelemedicineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Main Video Area (Patient)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.user, size: 120, color: Colors.white24),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.waitingForPatientLabel(
                      AppLocalizations.of(context)!.patientLabel,
                    ),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),

            // Doctor Self-View
            Positioned(
              top: 24,
              right: 24,
              child: Container(
                width: 100,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: const Center(
                  child: Icon(
                    LucideIcons.switchCamera,
                    color: Colors.white54,
                    size: 40,
                  ),
                ),
              ),
            ),

            // Patient Info Tab (Expandable)
            Positioned(
              top: 24,
              left: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.teal,
                      child: Icon(
                        LucideIcons.briefcaseMedical,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.patientLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(LucideIcons.chevronDown, color: Colors.white),
                  ],
                ),
              ),
            ),

            // Bottom Controls
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.only(bottom: 32, top: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black, Colors.black.withValues(alpha: 0)],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      LucideIcons.micOff,
                      Colors.white24,
                      Colors.white,
                    ),
                    _buildControlButton(
                      LucideIcons.video,
                      Colors.white24,
                      Colors.white,
                    ),
                    _buildControlButton(
                      LucideIcons.messageSquare,
                      Colors.white24,
                      Colors.white,
                    ),
                    _buildControlButton(
                      LucideIcons.phoneOff,
                      Colors.red,
                      Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton(IconData icon, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Icon(icon, color: iconColor, size: 28),
    );
  }
}
