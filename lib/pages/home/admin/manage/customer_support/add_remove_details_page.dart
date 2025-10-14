import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/customer_support.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/bloc/manage_app_bloc.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class AddRemoveDetailsPage extends StatefulWidget {
  final int index;
  final CustomerSupportModel? contact;
  const AddRemoveDetailsPage({super.key, required this.index, this.contact});

  @override
  State<AddRemoveDetailsPage> createState() => _AddRemoveDetailsPageState();
}

class _AddRemoveDetailsPageState extends State<AddRemoveDetailsPage> {
  final emailRegx = RegExp(
    r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$',
  );

  final phoneRegex = RegExp(
    r'^(009665|9665|\+9665|05|5)(5|0|3|6|4|9|1|8|7)[0-9]{7}$',
  );
  final whatsappRegex = RegExp(r'^(\+|00)?[1-9]\d{1,14}$');

  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ManageAppBloc, ManageAppState>(
      listener: (context, state) {
        if (state is CustomerSupportAdded) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.supportContactAddedSuccessfully,
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is CustomerSupportUpdated) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.supportContactUpdatedSuccessfully,
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is CustomerSupportDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.supportContactDeletedSuccessfully,
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is CustomerSupportAddError) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: Colors.red),
          );
        } else if (state is CustomerSupportUpdateError) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: Colors.red),
          );
        } else if (state is CustomerSupportDeleteError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(getAppBarTitles()[widget.index]),
          actions: [
            IconButton(
              onPressed: () {
                detailDialog(false);
              },
              icon: Icon(Icons.add, color: Colors.white),
            ),
          ],
        ),
        body: StreamBuilder<List<CustomerSupportModel>>(
          stream: AppServices.getCustomerServiceStreamByType(getTypeName()),
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

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text(AppLocalizations.of(context)!.noDataAvailable),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              itemCount: snapshot.data?.length ?? 0,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: snapshot.data![index].isActive ?? false
                          ? AppColors.primary.withOpacity(0.4)
                          : AppColors.primary.withOpacity(0.15),
                      width: snapshot.data![index].isActive ?? false ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: snapshot.data![index].isActive ?? false
                            ? AppColors.primary.withOpacity(0.1)
                            : Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          snapshot.data?[index].name ?? '',
                                          style: GoogleFonts.dmSans(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: Colors.black87,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ),
                                      if (snapshot.data![index].isActive ??
                                          false) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            "Primary",
                                            style: GoogleFonts.dmSans(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(
                                        0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      snapshot.data?[index].detail ?? '',
                                      style: GoogleFonts.dmSans(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, thickness: 1),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            BlocBuilder<ManageAppBloc, ManageAppState>(
                              builder: (context, state) {
                                final isDeleting =
                                    state is DeletingCustomerSupport;
                                return OutlinedButton.icon(
                                  onPressed: isDeleting
                                      ? null
                                      : () => _showDeleteConfirmation(
                                          context,
                                          snapshot.data![index],
                                        ),
                                  icon: Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                  ),
                                  label: Text(
                                    AppLocalizations.of(context)!.delete,
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.red,
                                    side: BorderSide(
                                      color: AppColors.red.withOpacity(0.5),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                detailDialog(
                                  true,
                                  contact: snapshot.data?[index],
                                  allContacts: snapshot.data!,
                                );
                              },
                              icon: Icon(Icons.edit_outlined, size: 18),
                              label: Text(
                                AppLocalizations.of(context)!.edit,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  getAppBarTitles() => [
        AppLocalizations.of(context)!.email,
        AppLocalizations.of(context)!.phone,
        AppLocalizations.of(context)!.whatsapp,
      ];

  void _showDeleteConfirmation(
    BuildContext context,
    CustomerSupportModel contact,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteConfirmation),
        content: Text(
          AppLocalizations.of(
            context,
          )!.areYouSureYouWantToDeleteThisSupportContact,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<ManageAppBloc>().add(
                    DeleteCustomerServiceContactEvent(contact.id ?? ''),
                  );
            },
            child: Text(
              AppLocalizations.of(context)!.delete,
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void detailDialog(
    bool isEdit, {
    CustomerSupportModel? contact,
    List<CustomerSupportModel>? allContacts,
  }) {
    nameController.clear();
    emailController.clear();

    // Local state for the switch
    bool isPrimaryValue = false;

    if (isEdit && contact != null) {
      nameController.text = contact.name;
      emailController.text = contact.detail;
      isPrimaryValue = contact.isActive ?? false;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return BlocBuilder<ManageAppBloc, ManageAppState>(
              builder: (context, state) {
                final isLoading =
                    state is AddingCustomerSupport ||
                    state is UpdatingCustomerSupport;

                return AlertDialog(
                  title: Text(isEdit ? getEditHeader() : getAddDialogHeader()),
                  content: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: nameController,
                          enabled: !isLoading,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.name,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)!.nameIsRequired;
                            }
                            return null;
                          },
                          maxLines: 1,
                          keyboardType: TextInputType.name,
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: emailController,
                          maxLength: widget.index == 1 ? 15 : null,
                          enabled: !isLoading,
                          decoration: InputDecoration(
                            labelText: getFieldLabel(),
                            counterText: "",
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return getFieldRequiredError();
                            }
                            if (widget.index == 0 &&
                                !getValidator().hasMatch(value)) {
                              return getErrorText();
                            }
                            return null;
                          },
                          maxLines: 1,
                          keyboardType: widget.index == 0
                              ? TextInputType.emailAddress
                              : TextInputType.phone,
                        ),
                        if (isEdit) ...[
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "Set as Primary",
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              Transform.scale(
                                scale: 0.85,
                                child: Switch(
                                  value: isPrimaryValue,
                                  activeColor: AppColors.primary,
                                  onChanged: isLoading
                                      ? null
                                      : (value) {
                                          setDialogState(() {
                                            isPrimaryValue = value;
                                          });
                                        },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () => Navigator.of(dialogContext).pop(),
                      child: Text(AppLocalizations.of(context)!.cancel),
                    ),
                    isLoading
                        ? SizedBox(width: 70, height: 20, child: Loader())
                        : TextButton(
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                final customerSupport = CustomerSupportModel(
                                  id: isEdit ? contact?.id : null,
                                  name: nameController.text.trim(),
                                  detail: emailController.text.trim(),
                                  type: getFieldLabel(),
                                  isActive: isEdit ? isPrimaryValue : false,
                                );

                                if (isEdit) {
                                  // Check if we need to update primary status
                                  if (isPrimaryValue &&
                                      contact?.isActive != true) {
                                    // Setting as new primary
                                    context.read<ManageAppBloc>().add(
                                          SetPrimaryCustomerServiceContactEvent(
                                            customerSupport,
                                            allContacts ?? [],
                                          ),
                                        );
                                  } else {
                                    // Regular update
                                    context.read<ManageAppBloc>().add(
                                          UpdateCustomerServiceContactEvent(
                                            customerSupport,
                                          ),
                                        );
                                  }
                                } else {
                                  context.read<ManageAppBloc>().add(
                                        AddCustomerServiceContactEvent(
                                          customerSupport,
                                        ),
                                      );
                                }
                              }
                            },
                            child: Text(
                              isEdit
                                  ? AppLocalizations.of(context)!.update
                                  : AppLocalizations.of(context)!.add,
                            ),
                          ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  String getAddDialogHeader() {
    switch (widget.index) {
      case 0:
        return AppLocalizations.of(context)!.addNewEmail;
      case 1:
        return AppLocalizations.of(context)!.addNewPhone;
      case 2:
        return AppLocalizations.of(context)!.addNewWhatsapp;
      default:
        return AppLocalizations.of(context)!.addNewEmail;
    }
  }

  String getEditHeader() {
    switch (widget.index) {
      case 0:
        return AppLocalizations.of(context)!.editEmail;
      case 1:
        return AppLocalizations.of(context)!.editPhone;
      case 2:
        return AppLocalizations.of(context)!.editWhatsapp;
      default:
        return AppLocalizations.of(context)!.editEmail;
    }
  }

  getValidator() {
    switch (widget.index) {
      case 0:
        return emailRegx;
      case 1:
        return phoneRegex;
      case 2:
        return whatsappRegex;
      default:
        return emailRegx;
    }
  }

  String getErrorText() {
    switch (widget.index) {
      case 0:
        return AppLocalizations.of(context)!.pleaseEnterValidEmail;
      case 1:
        return AppLocalizations.of(context)!.pleaseEnterAValidPhoneNumber;
      case 2:
        return AppLocalizations.of(context)!.pleaseEnterAValidPhoneNumber;
      default:
        return AppLocalizations.of(context)!.pleaseEnterValidEmail;
    }
  }

  String getFieldLabel() {
    switch (widget.index) {
      case 0:
        return AppLocalizations.of(context)!.email;
      case 1:
        return AppLocalizations.of(context)!.phone;
      case 2:
        return AppLocalizations.of(context)!.whatsapp;
      default:
        return AppLocalizations.of(context)!.email;
    }
  }

  String getTypeName() {
    switch (widget.index) {
      case 0:
        return "Email";
      case 1:
        return "Phone";
      case 2:
        return "WhatsApp";
      default:
        return "Email";
    }
  }

  String getFieldRequiredError() {
    switch (widget.index) {
      case 0:
        return AppLocalizations.of(context)!.emailIsRequired;
      case 1:
        return AppLocalizations.of(context)!.phoneIsRequired;
      case 2:
        return AppLocalizations.of(context)!.whatsappNumberIsRequired;
      default:
        return AppLocalizations.of(context)!.emailIsRequired;
    }
  }
}
