import 'package:flutter/material.dart';

import '../models/family_member.dart';
import '../services/family_service.dart';
import '../shared/widgets/empty_state_widget.dart';
import '../shared/widgets/success_overlay.dart';
import '../theme/app_spacing.dart';
import '../utils/form_padding.dart';
import '../widgets/owner_avatar.dart';
import '../widgets/safe_form_scaffold.dart';

class FamilyMembersScreen extends StatefulWidget {
  const FamilyMembersScreen({super.key});

  @override
  State<FamilyMembersScreen> createState() => _FamilyMembersScreenState();
}

class _FamilyMembersScreenState extends State<FamilyMembersScreen> {
  final _familyService = FamilyService.instance;
  List<FamilyMember> _members = [];

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  void _loadMembers() {
    setState(() {
      _members = _familyService.getAll();
    });
  }

  Future<void> _openMemberForm({FamilyMember? member}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => _FamilyMemberFormScreen(member: member),
      ),
    );

    if (saved == true) {
      _loadMembers();
    }
  }

  Future<void> _confirmDelete(FamilyMember member) async {
    if (member.id == 'self') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The default Self member cannot be deleted')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: dialogInsetPadding(context),
        title: const Text('Delete family member?'),
        content: Text('Delete "${member.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _familyService.delete(member.id);
    _loadMembers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Family Members'),
      ),
      body: SafeArea(
        child: _members.isEmpty
            ? EmptyStateWidget(
                icon: EmptyStateWidget.mutedIcon(context, Icons.group_outlined),
                title: 'No family members yet',
                subtitle: 'Tap + to add a family member.',
                semanticLabel:
                    'No family members yet. Tap plus to add a family member.',
              )
            : ListView.separated(
                padding: listScrollPadding(
                  context,
                  top: AppSpacing.fieldLabelGap,
                  includeFabClearance: true,
                ),
              itemCount: _members.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final member = _members[index];
                return ListTile(
                  leading: OwnerAvatar(ownerName: member.name, radius: 20),
                  title: Text(member.name),
                  subtitle: Text(member.relationship),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit',
                        onPressed: () => _openMemberForm(member: member),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Delete',
                        onPressed: () => _confirmDelete(member),
                      ),
                    ],
                  ),
                  onTap: () => _openMemberForm(member: member),
                );
              },
            ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openMemberForm(),
        child: const Icon(Icons.person_add),
      ),
    );
  }
}

class _FamilyMemberFormScreen extends StatefulWidget {
  const _FamilyMemberFormScreen({this.member});

  final FamilyMember? member;

  @override
  State<_FamilyMemberFormScreen> createState() =>
      _FamilyMemberFormScreenState();
}

class _FamilyMemberFormScreenState extends State<_FamilyMemberFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _familyService = FamilyService.instance;

  bool _isSaving = false;

  bool get _isEditMode => widget.member != null;

  @override
  void initState() {
    super.initState();
    final member = widget.member;
    if (member != null) {
      _nameController.text = member.name;
      _relationshipController.text = member.relationship;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    debugPrint('Save button tapped');

    FocusScope.of(context).unfocus();

    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      debugPrint('Form validation failed');
      return;
    }

    setState(() => _isSaving = true);

    try {
      debugPrint('Creating family member');
      final member = FamilyMember(
        id: _isEditMode
            ? widget.member!.id
            : DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        relationship: _relationshipController.text.trim(),
        photoPath: widget.member?.photoPath,
      );

      debugPrint('Saving to Hive');
      await _familyService.save(member);

      debugPrint('Save successful');
      if (!mounted) {
        return;
      }

      if (!_isEditMode) {
        await SuccessOverlay.showCelebration(
          context,
          message: 'Family member added',
        );
        if (!mounted) {
          return;
        }
      }

      Navigator.of(context).pop(true);
    } catch (error, stackTrace) {
      debugPrint('Save failed: $error');
      debugPrint('$stackTrace');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save family member: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewName = _nameController.text.trim().isEmpty
        ? 'Member'
        : _nameController.text.trim();

    return SafeFormScaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Member' : 'Add Member'),
      ),
      primaryLabel: _isEditMode ? 'Update' : 'Save',
      onPrimary: _save,
      primaryEnabled: !_isSaving,
      primaryChild: _isSaving
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: OwnerAvatar(ownerName: previewName, radius: 36),
              ),
              AppSpacing.gapSection,
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                ),
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              AppSpacing.gapField,
              TextFormField(
                controller: _relationshipController,
                decoration: const InputDecoration(
                  labelText: 'Relationship',
                  hintText: 'e.g. Spouse, Child, Parent',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a relationship';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
    );
  }
}
