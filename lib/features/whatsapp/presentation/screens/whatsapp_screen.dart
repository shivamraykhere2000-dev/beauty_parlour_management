import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/path_provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';

/// WhatsApp message templates — fully DB-backed via the `WhatsappTemplates`
/// table (seeded once with the original 5 defaults), so edits persist
/// across restarts.
///
/// Tapping a template card **opens** it in a detail dialog (view mode,
/// full text). From there, **Edit** switches the same dialog into an
/// editable text field; **Save** persists the change via
/// `updateWhatsappTemplate` and closes; **Cancel** discards the edit and
/// returns to view mode without touching the database. The `{{name}}`
/// placeholder mechanism and the "Send to Customer" flow are unchanged.
class WhatsAppScreen extends ConsumerWidget {
  const WhatsAppScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Idempotent: re-seeds the 5 defaults if the table is unexpectedly
    // empty (e.g. an existing install upgraded without the seed running).
    ref.watch(ensureWhatsappTemplatesSeededProvider);

    final AsyncValue<List<WhatsappTemplate>> templatesAsync =
        ref.watch(whatsappTemplatesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: 'WhatsApp Templates',
        onBack: onBack,
      ),
      body: templatesAsync.when(
        loading: () => const LoadingWidget(),
        error: (Object e, _) => AppErrorWidget(message: '$e'),
        data: (List<WhatsappTemplate> templates) {
          if (templates.isEmpty) {
            return EmptyWidget(
              icon: Icons.chat_bubble_outline,
              title: 'No templates yet',
              message: 'Add your first WhatsApp template to get started.',
              actionLabel: 'Add Template',
              onAction: () => _openAddTemplateDialog(context, ref),
            );
          }
          return ListView(
            padding: EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxxl),
            children: <Widget>[
              for (final WhatsappTemplate t in templates) ...<Widget>[
                AppCard(
                  onTap: () => _openTemplate(context, ref, t),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(t.emoji, style: TextStyle(fontSize: 20.sp)),
                          SizedBox(width: AppSpacing.xs),
                          Expanded(
                              child: Text(t.type,
                                  style:
                                      AppTypography.label(AppColors.foreground)
                                          .copyWith(
                                              fontWeight: AppTypography.bold))),
                          const Icon(Icons.chevron_right,
                              size: 18, color: AppColors.mutedForeground),
                        ],
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(t.body,
                          style:
                              AppTypography.caption(AppColors.mutedForeground),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      SizedBox(height: AppSpacing.sm),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: AppButton(
                              label: 'Edit',
                              icon: Icons.edit,
                              variant: AppButtonVariant.outlined,
                              onPressed: () => _openTemplate(context, ref, t,
                                  startInEditMode: true),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
              ],
            ],
          );
        },
      ),
    );
  }

  /// Opens the template detail dialog. Set [startInEditMode] to jump
  /// straight into editing (used by the row's "Edit" shortcut); tapping
  /// the card itself opens in view mode first, matching "Open template →
  /// Edit template → Save/Cancel".
  void _openTemplate(
      BuildContext context, WidgetRef ref, WhatsappTemplate template,
      {bool startInEditMode = false}) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => _TemplateDetailDialog(
        template: template,
        startInEditMode: startInEditMode,
        onSend: () {
          Navigator.of(context).pop();
          _pickCustomerAndSend(context, ref, template);
        },
      ),
    );
  }

  /// Opens a dialog to create a brand-new custom template (type name,
  /// emoji, body), inserted via `addWhatsappTemplate`.
  void _openAddTemplateDialog(BuildContext context, WidgetRef ref) {
    final TextEditingController typeController = TextEditingController();
    final TextEditingController emojiController =
        TextEditingController(text: '💬');
    final TextEditingController bodyController = TextEditingController();

    AppDialog.show(
      context,
      title: 'Add Template',
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AppTextField(
                label: 'TEMPLATE NAME',
                hint: 'e.g. Diwali Offer',
                controller: typeController),
            SizedBox(height: AppSpacing.sm),
            AppTextField(
                label: 'EMOJI', hint: '💬', controller: emojiController),
            SizedBox(height: AppSpacing.sm),
            Text("Use {{name}} where the customer's name should go.",
                style: AppTypography.caption(AppColors.mutedForeground)),
            SizedBox(height: AppSpacing.xs),
            TextField(
              controller: bodyController,
              maxLines: 6,
              style: AppTypography.bodyMedium(AppColors.foreground),
              decoration:
                  const InputDecoration(hintText: 'Template message...'),
            ),
          ],
        ),
      ),
      primaryActionLabel: 'Save',
      onPrimaryAction: () async {
        if (typeController.text.trim().isEmpty ||
            bodyController.text.trim().isEmpty) {
          AppSnackBar.show(context,
              message: 'Please enter a name and message.',
              type: AppSnackBarType.error);
          return;
        }
        await ref.read(whatsappTemplatesDaoProvider).addWhatsappTemplate(
              type: typeController.text.trim(),
              emoji: emojiController.text.trim(),
              body: bodyController.text.trim(),
            );
        if (context.mounted) {
          Navigator.of(context).pop();
          AppSnackBar.show(context,
              message: 'Template added.', type: AppSnackBarType.success);
        }
      },
      secondaryActionLabel: 'Cancel',
    );
  }

  void _pickCustomerAndSend(
      BuildContext context, WidgetRef ref, WhatsappTemplate template) {
    AppDialog.show(
      context,
      title: 'Send "${template.type}" to...',
      content: SizedBox(
        width: double.maxFinite,
        height: 320,
        child: Consumer(
          builder: (BuildContext context, WidgetRef ref, _) {
            final AsyncValue<List<Customer>> customersAsync =
                ref.watch(customersProvider);
            return customersAsync.when(
              loading: () => const LoadingWidget(),
              error: (Object e, _) => AppErrorWidget(message: '$e'),
              data: (List<Customer> customers) => ListView(
                shrinkWrap: true,
                children: <Widget>[
                  for (final Customer c in customers)
                    ListTile(
                      leading: AppAvatar(
                          initials: c.avatarInitials, size: AppAvatarSize.sm),
                      title: Text(c.name,
                          style:
                              AppTypography.bodyMedium(AppColors.foreground)),
                      subtitle: Text(c.phone,
                          style:
                              AppTypography.caption(AppColors.mutedForeground)),
                      onTap: () async {
                        Navigator.of(context).pop();
                        await _launchWhatsApp(c.phone,
                            template.body.replaceAll('{{name}}', c.name));
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
      secondaryActionLabel: 'Cancel',
    );
  }

  Future<void> _launchWhatsApp(String phone, String message) async {
    final String digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final String withCountryCode = digits.length == 10 ? '91$digits' : digits;
    final Uri uri = Uri.parse(
        'https://wa.me/$withCountryCode?text=${Uri.encodeComponent(message)}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// The Open/View → Edit → Save/Cancel dialog for a single template.
class _TemplateDetailDialog extends ConsumerStatefulWidget {
  const _TemplateDetailDialog({
    required this.template,
    required this.onSend,
    this.startInEditMode = false,
  });

  final WhatsappTemplate template;
  final bool startInEditMode;
  final VoidCallback onSend;

  @override
  ConsumerState<_TemplateDetailDialog> createState() =>
      _TemplateDetailDialogState();
}

class _TemplateDetailDialogState extends ConsumerState<_TemplateDetailDialog> {
  late bool _editing = widget.startInEditMode;

  late final TextEditingController _controller = TextEditingController(
    text: widget.template.body,
  );

  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String newBody = _controller.text.trim();

    if (newBody.isEmpty) {
      AppSnackBar.show(
        context,
        message: 'Template cannot be empty.',
        type: AppSnackBarType.error,
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await ref.read(whatsappTemplatesDaoProvider).updateWhatsappTemplate(
            widget.template.copyWith(
              body: newBody,
            ),
          );

      if (!mounted) return;

      Navigator.of(context).pop();

      AppSnackBar.show(
        context,
        message: 'Template updated.',
        type: AppSnackBarType.success,
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'Could not save template: $e',
          type: AppSnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _cancelEdit() {
    setState(() {
      _controller.text = widget.template.body;
      _editing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: <Widget>[
          Text(
            widget.template.emoji,
            style: TextStyle(fontSize: 20.sp),
          ),
          SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              widget.template.type,
              style: AppTypography.h3(
                AppColors.foreground,
              ).copyWith(
                fontSize: 16.sp,
              ),
            ),
          ),
        ],
      ),

      content: SizedBox(
        width: double.maxFinite,
        child: _editing
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    "Use {{name}} where the customer's name should go.",
                    style: AppTypography.caption(
                      AppColors.mutedForeground,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _controller,
                    maxLines: 6,
                    autofocus: true,
                    style: AppTypography.bodyMedium(
                      AppColors.foreground,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Template message...',
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                child: Text(
                  widget.template.body,
                  style: AppTypography.bodyMedium(
                    AppColors.foreground,
                  ),
                ),
              ),
      ),

      actionsPadding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),

// IMPORTANT:
// AlertDialog.actions uses an OverflowBar internally.
// Therefore Expanded cannot be used directly inside actions.
//
// The Row below creates the required Flex parent for Expanded.
      actions: <Widget>[
        Row(
          children: _editing
              ? <Widget>[
                  Expanded(
                    child: AppButton(
                      label: 'Cancel',
                      variant: AppButtonVariant.outlined,
                      size: AppButtonSize.medium,
                      onPressed: _saving ? null : _cancelEdit,
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton(
                      label: 'Save',
                      size: AppButtonSize.medium,
                      onPressed: _saving ? null : _save,
                      isLoading: _saving,
                    ),
                  ),
                ]
              : <Widget>[
                  Expanded(
                    child: AppButton(
                      label: 'Close',
                      variant: AppButtonVariant.outlined,
                      size: AppButtonSize.medium,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton(
                      label: 'Edit',
                      size: AppButtonSize.medium,
                      onPressed: () {
                        setState(() => _editing = true);
                      },
                    ),
                  ),
                ],
        ),
      ],
    );
  }
}
