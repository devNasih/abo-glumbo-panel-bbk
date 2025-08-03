import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/widgets/agent_tile.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:flutter/material.dart';

class ManageAgents extends StatelessWidget {
  const ManageAgents({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.manageAgents)),
      body: StreamBuilder(
        stream: AppServices.getAllAgentsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: Loader(size: 50));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No agents found.'));
          }

          final agents = snapshot.data!;
          return ListView.builder(
            itemCount: agents.length,
            itemBuilder: (context, index) {
              final agent = agents[index];
              return AgentTileMinimal(
                user: agent,
                isVerified: agent.isVerified ?? false,
                onTap: () {
                  // Handle agent tile tap
                },
                onApprovalToggle: () {
                  // Handle approval toggle
                },
              );
            },
          );
        },
      ),
    );
  }
}
