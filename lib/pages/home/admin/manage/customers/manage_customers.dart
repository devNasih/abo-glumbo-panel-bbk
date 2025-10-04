import 'dart:developer';

import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/bloc/manage_app_bloc.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/widgets/customer_tile.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ManageCustomersPage extends StatefulWidget {
  const ManageCustomersPage({super.key});

  @override
  State<ManageCustomersPage> createState() => _ManageCustomersPageState();
}

class _ManageCustomersPageState extends State<ManageCustomersPage> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<ManageAppBloc, ManageAppState>(
      listener: (context, state) {
        if (state is BlockUnblockCustomer) {
          log('state.isBlocked=${state.isBlocked}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.isBlocked
                    ? AppLocalizations.of(context)!.customerBlockedSuccessfully
                    : AppLocalizations.of(
                        context,
                      )!.customerUnblockedSuccessfully,
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: state.isBlocked ? Colors.red : Colors.green,
            ),
          );
        } else if (state is BlockUnblockCustomerError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppLocalizations.of(context)!.error}: ${state.error}',
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.manageCustomers),
        ),
        body: StreamBuilder(
          stream: AppServices.getAllCustomersStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: Loader());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  '${AppLocalizations.of(context)!.error}: ${snapshot.error}',
                ),
              );
            }
            if (!snapshot.hasData || (snapshot.data?.isEmpty ?? true)) {
              return Center(
                child: Text(AppLocalizations.of(context)!.noCustomersFound),
              );
            }
            final customers = snapshot.data!;
            return ListView.builder(
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final customer = customers[index];
                return CustomerTileMinimal(
                  customer: customer,
                  isBlocked: customer.isBlocked ?? false,
                  onTap: () {
                    // Handle customer tap if needed
                  },
                  onApprovalToggle: () {
                    context.read<ManageAppBloc>().add(
                      CustomerBlockUnblockEvent(
                        customer.uid,
                        !(customer.isBlocked ?? false),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
