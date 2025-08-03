import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/widgets/tips_tile.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:flutter/material.dart';

class ManageTips extends StatelessWidget {
  const ManageTips({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.manageTipping)),
      body: StreamBuilder(
        stream: AppServices.getTippingStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(AppLocalizations.of(context)!.error));
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(AppLocalizations.of(context)!.noTipsAvailable),
            );
          }

          final tips = snapshot.data!;

          return ListView.builder(
            itemCount: tips.length,
            itemBuilder: (context, index) {
              final tip = tips[index];
              return TipsTileCompact(tip: tip);
            },
          );
        },
      ),
    );
  }
}
