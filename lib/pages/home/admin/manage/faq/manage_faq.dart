import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/faq.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/bloc/manage_app_bloc.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/faq/edit_faq.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ManageFaq extends StatefulWidget {
  const ManageFaq({super.key});

  @override
  State<ManageFaq> createState() => _ManageFaqState();
}

class _ManageFaqState extends State<ManageFaq> {
  // Tracks whether the delete confirmation/loading dialog is currently shown.
  bool _isDeletingDialogShowing = false;
  @override
  Widget build(BuildContext context) {
    bool isEnglish = Directionality.of(context) == TextDirection.ltr;
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.manageFaqs)),
      body: BlocListener<ManageAppBloc, ManageAppState>(
        listener: (context, state) {
          // Show the loading dialog only when deleting and it's not shown.
          if (state is DeletingFaq) {
            if (!_isDeletingDialogShowing) {
              _isDeletingDialogShowing = true;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => Center(child: Loader()),
              ).then((_) => _isDeletingDialogShowing = false);
            }
          } else {
            // Only pop the root navigator if the delete dialog was shown.
            if (_isDeletingDialogShowing) {
              try {
                Navigator.of(context, rootNavigator: true).pop();
              } catch (_) {}
              _isDeletingDialogShowing = false;
            }
          }

          if (state is FaqDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.faqEntryDeletedSuccessfully,
                ),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.green,
              ),
            );
            if (mounted) {
              Navigator.pop(context);
            }
          }

          if (state is FaqDeleteError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${AppLocalizations.of(context)!.error}: ${state.error}',
                ),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.red,
              ),
            );
            if (mounted) {
              Navigator.pop(context);
            }
          }
        },
        child: StreamBuilder<List<FaqModel>>(
          stream: AppServices.getFaqStream(),
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

            final faqEntries = snapshot.data ?? [];
            if (faqEntries.isEmpty) {
              return Center(
                child: Text(AppLocalizations.of(context)!.noFaqEntriesFound),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: 100,
              ),
              itemCount: faqEntries.length,
              itemBuilder: (context, index) {
                final entry = faqEntries[index];

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      spacing: 5,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                child: Text(
                                  isEnglish
                                      ? entry.questionEn
                                      : entry.questionAr,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Flexible(
                                child: Text(
                                  isEnglish ? entry.answerEn : entry.answerAr,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${AppLocalizations.of(context)!.positionText}: ${entry.stand}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            IconButton(
                              style: ButtonStyle(
                                backgroundColor: WidgetStatePropertyAll(
                                  AppColors.primary,
                                ),
                                shape: WidgetStatePropertyAll(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AddFaqPage(faq: entry, isEdit: true),
                                ),
                              ),
                              icon: Icon(
                                Icons.edit,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),

                            BlocBuilder<ManageAppBloc, ManageAppState>(
                              builder: (context, state) {
                                return IconButton(
                                  style: ButtonStyle(
                                    backgroundColor: WidgetStatePropertyAll(
                                      Colors.red,
                                    ),
                                    shape: WidgetStatePropertyAll(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) =>
                                          confirmDeleteDialog(entry),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.delete_forever,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to AddFaqPage (to be implemented)
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddFaqPage(isEdit: false),
            ),
          );
        },
        tooltip: AppLocalizations.of(context)!.addFaq,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget confirmDeleteDialog(FaqModel entry) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.deleteFaqEntry),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocalizations.of(context)!.areYouSureYouWantToDeleteThisFaqEntry,
          ),
          Text(AppLocalizations.of(context)!.thisActionCannotBeUndone),
        ],
      ),
      actions: [
        TextButton(
          child: Text(AppLocalizations.of(context)!.cancel),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: Text(AppLocalizations.of(context)!.delete),
          onPressed: () {
            context.read<ManageAppBloc>().add(DeleteFaqEvent(entry.id));
          },
        ),
      ],
    );
  }
}
