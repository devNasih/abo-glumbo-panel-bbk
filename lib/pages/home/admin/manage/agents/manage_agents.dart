import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/agents/agent_info.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/bloc/manage_app_bloc.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/widgets/agent_tile.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ManageAgents extends StatelessWidget {
  const ManageAgents({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ManageAppBloc, ManageAppState>(
      listener: (context, state) {
        if (state is AgentApproved) {
          // Show a snackbar or dialog based on the approval result
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.isApproved
                    ? 'Agent approved successfully.'
                    : 'Agent disapproved successfully.',
              ),
            ),
          );
        }
      },
      child: Scaffold(
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
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AgentInfo(agent: agent),
                    ),
                  ),
                  onApprovalToggle: agent.uid != null
                      ? () => context.read<ManageAppBloc>().add(
                          ApproveRejectAgentEvent(
                            (agent.uid ?? ''),
                            !(agent.isVerified ?? false),
                          ),
                        )
                      : null,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
