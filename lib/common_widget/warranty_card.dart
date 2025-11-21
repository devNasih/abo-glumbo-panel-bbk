import 'package:aboglumbo_bbk_panel/models/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aboglumbo_bbk_panel/models/warranty.dart';
import 'package:intl/intl.dart';

Widget warrantyClaimCard({
  required BuildContext context,
  required WarrantyModel warranty,
  required String bookingId,
  required String bookingName,
  required String customerName,
  required String technicianName,
  required DateTime? serviceCompletedDate,
  required bool isAccepted,
  required bool isTrackingStarted,
  required bool isWorkCompleted,
  VoidCallback? onAccept,
  VoidCallback? onReject,
  VoidCallback? onStartWork,
  VoidCallback? onStopTracking,
  VoidCallback? onCompleteWork,
  VoidCallback? onCancel,
  UserModel? currentUser,
}) {
  // Status configuration
  String statusLabel;
  Color statusColor;
  IconData statusIcon;
  Color statusBgColor;

  if (isWorkCompleted) {
    statusLabel = 'Completed';
    statusColor = Colors.white;
    statusBgColor = const Color(0xFF4CAF50);
    statusIcon = Icons.check_circle_rounded;
  } else {
    statusLabel = 'Pending Review';
    statusColor = Colors.white;
    statusBgColor = const Color(0xFFFF9800);
    statusIcon = Icons.pending_rounded;
  }

  // Format date
  String formattedDate = serviceCompletedDate != null
      ? DateFormat('dd MMM yyyy, HH:mm').format(serviceCompletedDate)
      : "N/A";

  // Button configuration based on workflow state
  List<Widget> buttonWidgets = [];

  if (!isAccepted && !isWorkCompleted) {
    // Step 1: Accept or Reject
    buttonWidgets.addAll([
      Expanded(
        child: ElevatedButton.icon(
          onPressed: onAccept,
          icon: const Icon(Icons.check_circle_outline, size: 20),
          label: const Text('Accept'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: OutlinedButton.icon(
          onPressed: onReject,
          icon: const Icon(Icons.close_rounded, size: 20),
          label: const Text('Reject'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFE53935),
            side: const BorderSide(color: Color(0xFFE53935), width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    ]);
  } else if (isAccepted && !isTrackingStarted && !isWorkCompleted) {
    // Step 2: Start work or cancel
    buttonWidgets.addAll([
      Expanded(
        child: ElevatedButton.icon(
          onPressed: onStartWork,
          icon: const Icon(Icons.play_arrow_rounded, size: 20),
          label: const Text('Start Work'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2196F3),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: OutlinedButton.icon(
          onPressed: onCancel,
          icon: const Icon(Icons.cancel_outlined, size: 20),
          label: const Text('Cancel'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey[700],
            side: BorderSide(color: Colors.grey[400]!, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    ]);
  } else if (isTrackingStarted && !isWorkCompleted) {
    // Step 3: Stop tracking or complete
    buttonWidgets.addAll([
      Expanded(
        child: OutlinedButton.icon(
          onPressed: onStopTracking,
          icon: const Icon(Icons.pause_circle_outline, size: 20),
          label: const Text('Pause'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFFF9800),
            side: const BorderSide(color: Color(0xFFFF9800), width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: ElevatedButton.icon(
          onPressed: onCompleteWork,
          icon: const Icon(Icons.task_alt_rounded, size: 20),
          label: const Text('Complete'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    ]);
  } else if (isWorkCompleted) {
    // Work completed - show disabled state
    buttonWidgets.add(
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Work Completed',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Rejected technicians widget
  Widget? rejectedTechWidget;
  if (warranty.rejectedTechnicians != null &&
      warranty.rejectedTechnicians!.isNotEmpty) {
    rejectedTechWidget = Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.red[700]),
              const SizedBox(width: 6),
              Text(
                'Rejection History',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.red[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...warranty.rejectedTechnicians!.map(
            (technician) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                "• ${technician.name} - ${technician.rejectedOn != null ? DateFormat('dd/MM/yyyy').format(technician.rejectedOn!) : 'N/A'}",
                style: TextStyle(fontSize: 12, color: Colors.red[800]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    elevation: 2,
    shadowColor: Colors.black26,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status header with gradient
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [statusBgColor, statusBgColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 22),
              const SizedBox(width: 8),
              Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (isTrackingStarted)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.radio_button_checked,
                        color: statusColor,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tracking',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Card content
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service name
              Text(
                bookingName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 12),

              // Booking ID with copy function
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.bookmark_outline,
                      size: 18,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ID: $bookingId',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[800],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: bookingId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text('Booking ID copied!'),
                              ],
                            ),
                            backgroundColor: const Color(0xFF4CAF50),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.copy_rounded,
                          size: 18,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Customer info
              _buildInfoRow(
                icon: Icons.person_outline_rounded,
                label: 'Customer',
                value: customerName,
                color: const Color(0xFF2196F3),
              ),
              const SizedBox(height: 10),

              // Technician info (admin only)
              if (currentUser?.isAdmin ?? false) ...[
                _buildInfoRow(
                  icon: Icons.engineering_outlined,
                  label: 'Technician',
                  value: technicianName,
                  color: const Color(0xFFFF9800),
                ),
                const SizedBox(height: 10),
              ],

              // Date
              _buildInfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Completed',
                value: formattedDate,
                color: const Color(0xFF9C27B0),
              ),

              // Rejection history (admin only)
              if ((currentUser?.isAdmin ?? false) && rejectedTechWidget != null)
                rejectedTechWidget,

              // Action buttons (non-admin only)
              if (!(currentUser?.isAdmin ?? false) &&
                  buttonWidgets.isNotEmpty) ...[
                const SizedBox(height: 20),
                Row(children: buttonWidgets),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildInfoRow({
  required IconData icon,
  required String label,
  required String value,
  required Color color,
}) {
  return Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF212121),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
