import 'package:flutter/material.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/booking.dart';

class BookingControlsWidget extends StatelessWidget {
  final BookingModel booking;
  final bool isTracking;
  final bool isLoading;
  final VoidCallback onCancelBooking;
  final VoidCallback onStartTracking;
  final VoidCallback onStopTracking;
  final VoidCallback onCompleteWork;

  const BookingControlsWidget({
    super.key,
    required this.booking,
    required this.isTracking,
    required this.isLoading,
    required this.onCancelBooking,
    required this.onStartTracking,
    required this.onStopTracking,
    required this.onCompleteWork,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric( vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Action buttons
          Row(
            children: [
              Expanded(
                child: _buildButton(
                  onPressed: () => _showCancelDialog(context),
                  label: AppLocalizations.of(context)!.cancelBooking,
                  color: Colors.red.shade50,
                  textColor: Colors.red.shade700,
                  borderColor: Colors.red.shade200,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildButton(
                  onPressed: isTracking ? onStopTracking : onStartTracking,
                  label: isTracking
                      ? AppLocalizations.of(context)!.stopTracking
                      : AppLocalizations.of(context)!.startTracking,
                  color: isTracking
                      ? Colors.orange.shade50
                      : Colors.blue.shade50,
                  textColor: isTracking
                      ? Colors.orange.shade700
                      : Colors.blue.shade700,
                  borderColor: isTracking
                      ? Colors.orange.shade200
                      : Colors.blue.shade200,
                  isLoading: isLoading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Complete button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onCompleteWork,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.completeWork,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildButton({
    required VoidCallback onPressed,
    required String label,
    required Color color,
    required Color textColor,
    required Color borderColor,
    bool isLoading = false,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: textColor,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.cancelBooking),
          content: Text(
            AppLocalizations.of(context)!.areYouSureYouWantToCancelThisBooking,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.no),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onCancelBooking();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }
}
