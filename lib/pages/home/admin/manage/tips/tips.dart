import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/bloc/manage_app_bloc.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/widgets/tips_tile.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/sheets/tips_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ManageTips extends StatelessWidget {
  const ManageTips({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ManageAppBloc, ManageAppState>(
      listener: (context, state) {
        if (state is WalletClearError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.error)));
        } else if (state is WalletCleared) {
          Navigator.pop(context);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.walletClearedSuccessfully,
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.manageTipping),
        ),
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
                return TipsTileCompact(
                  tip: tip,
                  onTap: () => showTipDetailsBottomSheet(
                    tip,
                    context,
                    onClearWallet: (tip) => context.read<ManageAppBloc>().add(
                      ClearTipWalletEvent(tip.agentId ?? ''),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
