import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/faq.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/bloc/manage_app_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddFaqPage extends StatefulWidget {
  const AddFaqPage({super.key});

  @override
  State<AddFaqPage> createState() => _AddFaqPageState();
}

class _AddFaqPageState extends State<AddFaqPage> {
  final _formKey = GlobalKey<FormState>();
  int? stand = 0;

  // Tracks whether the modal loading dialog is currently visible so we don't
  // accidentally pop the navigator when it's not shown.
  bool _isDialogShowing = false;

  final TextEditingController _questionEnController = TextEditingController();
  final TextEditingController _answerEnController = TextEditingController();
  final TextEditingController _questionOtherController =
      TextEditingController();
  final TextEditingController _answerOtherController = TextEditingController();
  final TextEditingController standController = TextEditingController();

  @override
  void dispose() {
    _questionEnController.dispose();
    _answerEnController.dispose();
    _questionOtherController.dispose();
    _answerOtherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.addFaqEntry),
        actions: [
          BlocBuilder<ManageAppBloc, ManageAppState>(
            builder: (context, state) {
              return IconButton(
                icon: const Icon(Icons.save),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final faqEntry = FaqModel(
                      id: "",
                      stand,
                      questionEn: _questionEnController.text.trim(),
                      questionAr: _questionOtherController.text.trim(),
                      answerEn: _answerEnController.text.trim(),
                      answerAr: _answerOtherController.text.trim(),
                    );
                    context.read<ManageAppBloc>().add(AddFaqEvent(faqEntry));
                  }
                },
              );
            },
          ),
        ],
      ),
      body: BlocListener<ManageAppBloc, ManageAppState>(
        listener: (context, state) async {
          // Track whether the loader dialog is currently shown so we don't
          // accidentally pop the page navigator when no dialog exists.
          // Using a state variable on the State object.
          if (state is AddingFaq) {
            if (!_isDialogShowing) {
              _isDialogShowing = true;
              showDialog(
                context: context,
                barrierDismissible: false,
                useRootNavigator: true,
                builder: (context) => Center(child: Loader()),
              ).then((_) {
                // Dialog dismissed
                _isDialogShowing = false;
              });
            }
            return;
          }

          // If we reach here and the dialog is showing, dismiss it.
          if (_isDialogShowing) {
            try {
              Navigator.of(context, rootNavigator: true).pop();
            } catch (_) {}
            _isDialogShowing = false;
          }

          if (state is FaqAdded) {
            // Show a yellow (amber) snackbar and then close this page after
            // the SnackBar has been dismissed so the user sees the message.
            final controller = ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.amber,
                content: Text(
                  AppLocalizations.of(context)!.faqAddedSuccessfully,
                ),
              ),
            );
            try {
              await controller.closed;
            } catch (_) {}
            if (mounted) Navigator.of(context).pop();
            return;
          }

          if (state is FaqAddError) {
            state.error.contains('already exists')
                ? ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.amber,
                      content: Text(
                        AppLocalizations.of(context)!.entryAlreadyExists,
                      ),
                    ),
                  )
                : ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.amber,
                      content: Text(
                        '${AppLocalizations.of(context)!.error}: ${state.error}',
                      ),
                    ),
                  );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: standController,
                  decoration: InputDecoration(
                    labelText:
                        AppLocalizations.of(context)?.sortOrder ?? 'Sort Order',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) {
                    int? parsedValue = int.tryParse(value);
                    if (parsedValue != null) {
                      setState(() {
                        stand = parsedValue;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(
                            context,
                          )?.pleaseEnterSortOrder ??
                          'Please enter sort order';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.english,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _questionEnController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.question,
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? AppLocalizations.of(context)!.questionIsRequired
                      : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _answerEnController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.answer,
                  ),

                  validator: (value) => value == null || value.isEmpty
                      ? AppLocalizations.of(context)!.answerIsRequired
                      : null,
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)!.arabic,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _questionOtherController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.question,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.questionIsRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _answerOtherController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.answer,
                  ),

                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.answerIsRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
