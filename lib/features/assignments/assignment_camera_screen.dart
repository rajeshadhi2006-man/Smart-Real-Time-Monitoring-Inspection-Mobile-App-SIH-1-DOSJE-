import 'package:flutter/material.dart';
import '../../models/assignment_model.dart';
import '../evidence/live_gps_map_camera_screen.dart';

/// Assignment Camera Screen
/// Unifies directly with LiveGpsMapCameraScreen to ensure strictly in-app hardware camera streaming
/// with live GPS Map Camera watermark HUD and zero file picker/upload dialog.
class AssignmentCameraScreen extends StatelessWidget {
  final AssignmentModel assignment;

  const AssignmentCameraScreen({super.key, required this.assignment});

  @override
  Widget build(BuildContext context) {
    return LiveGpsMapCameraScreen(
      assignment: assignment,
      forAssignmentCompletion: true,
    );
  }
}
