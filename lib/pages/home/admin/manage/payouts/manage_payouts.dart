import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/payouts/payout_request_card.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/material.dart';

class ManagePayouts extends StatelessWidget {
  const ManagePayouts({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.managePayouts),

        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder(stream: AppServices.getAllPayoutRequests() , builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('${AppLocalizations.of(context)!.error}: ${snapshot.error}'));
        }
        final payoutRequests = snapshot.data ?? [];
        if (payoutRequests.isEmpty) {
          return  Center(child: Text(AppLocalizations.of(context)!.noPayoutRequestsFound));
        } else {
          return ListView.builder(
            itemCount: payoutRequests.length,
            itemBuilder: (context, index) {
              final payoutRequest = payoutRequests[index];
              return PayoutRequestCard(payoutRequest: payoutRequest);
            },
          );
        }
      }),
    );
  }
}
