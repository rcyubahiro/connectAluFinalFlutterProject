import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/opportunity_model.dart';
import '../../../features/auth/providers/auth_providers.dart';
import '../../../features/opportunities/providers/opportunity_providers.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Admin Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) context.go('/admin/login');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.add_circle_outline), text: 'Post'),
            Tab(icon: Icon(Icons.list_alt_outlined), text: 'Manage'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _PostOpportunityForm(),
          _ManageOpportunities(),
        ],
      ),
    );
  }
}

// ── Post Opportunity Form ──
class _PostOpportunityForm extends ConsumerStatefulWidget {
  const _PostOpportunityForm();

  @override
  ConsumerState<_PostOpportunityForm> createState() =>
      _PostOpportunityFormState();
}

class _PostOpportunityFormState extends ConsumerState<_PostOpportunityForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();
  final _startupNameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  OpportunityCategory _category = OpportunityCategory.engineering;
  CommitmentType _commitment = CommitmentType.flexible;
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _skillsCtrl.dispose();
    _startupNameCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final skills = _skillsCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      await ref.read(opportunityRepositoryProvider).createOpportunity(
            Opportunity(
              id: '',
              startupId: 'admin',
              startupName: _startupNameCtrl.text.trim(),
              title: _titleCtrl.text.trim(),
              description: _descCtrl.text.trim(),
              category: _category,
              skillsRequired: skills,
              commitment: _commitment,
              location: _locationCtrl.text.trim(),
              status: OpportunityStatus.open,
              createdAt: DateTime.now(),
            ),
          );
      if (mounted) {
        _titleCtrl.clear();
        _descCtrl.clear();
        _skillsCtrl.clear();
        _startupNameCtrl.clear();
        _locationCtrl.clear();
        setState(() {
          _category = OpportunityCategory.engineering;
          _commitment = CommitmentType.flexible;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Opportunity posted successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            _label('Role Title *'),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. UX Research Volunteer',
                prefixIcon: Icon(Icons.work_outline),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            _label('Organization / Startup *'),
            TextFormField(
              controller: _startupNameCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. EduBridge',
                prefixIcon: Icon(Icons.storefront_outlined),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            _label('Location'),
            TextFormField(
              controller: _locationCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. Kigali, Remote, On-campus',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 14),
            _label('Description & Responsibilities *'),
            TextFormField(
              controller: _descCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Describe the role, tasks, and expectations...',
                prefixIcon: Icon(Icons.description_outlined),
                alignLabelWithHint: true,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            _label('Skills Required'),
            TextFormField(
              controller: _skillsCtrl,
              decoration: const InputDecoration(
                hintText: 'Flutter, Figma, Python...',
                prefixIcon: Icon(Icons.psychology_outlined),
              ),
            ),
            const SizedBox(height: 14),
            _label('Category'),
            DropdownButtonFormField<OpportunityCategory>(
              initialValue: _category,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: OpportunityCategory.values
                  .map((c) => DropdownMenuItem(
                      value: c, child: Text(_categoryLabel(c))))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 14),
            _label('Commitment Type'),
            DropdownButtonFormField<CommitmentType>(
              initialValue: _commitment,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.schedule_outlined),
              ),
              items: CommitmentType.values
                  .map((c) => DropdownMenuItem(
                      value: c, child: Text(_commitmentLabel(c))))
                  .toList(),
              onChanged: (v) => setState(() => _commitment = v!),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.publish_rounded),
              label: Text(_submitting ? 'Posting...' : 'Post Opportunity'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E))),
      );

  String _categoryLabel(OpportunityCategory c) {
    const map = {
      OpportunityCategory.engineering: 'Engineering',
      OpportunityCategory.design: 'Design',
      OpportunityCategory.marketing: 'Marketing',
      OpportunityCategory.operations: 'Operations',
      OpportunityCategory.research: 'Research',
      OpportunityCategory.businessAnalysis: 'Business Analysis',
      OpportunityCategory.contentCreation: 'Content Creation',
      OpportunityCategory.communityManagement: 'Community Management',
    };
    return map[c] ?? c.name;
  }

  String _commitmentLabel(CommitmentType c) {
    switch (c) {
      case CommitmentType.partTime:
        return 'Part-time';
      case CommitmentType.projectBased:
        return 'Project-based';
      case CommitmentType.flexible:
        return 'Flexible';
    }
  }
}

// ── Manage Opportunities ──
class _ManageOpportunities extends ConsumerWidget {
  const _ManageOpportunities();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(openOpportunitiesProvider);

    return feedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (opps) {
        if (opps.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.work_off_outlined,
                    size: 56, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('No opportunities posted yet',
                    style: TextStyle(color: Colors.grey.shade500)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: opps.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _OpportunityTile(opportunity: opps[i]),
        );
      },
    );
  }
}

class _OpportunityTile extends ConsumerWidget {
  final Opportunity opportunity;
  const _OpportunityTile({required this.opportunity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.work_outline,
                color: AppTheme.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(opportunity.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 2),
                Text(opportunity.startupName,
                    style:
                        TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    _badge(_commitmentLabel(opportunity.commitment),
                        AppTheme.primary),
                    if (opportunity.location.isNotEmpty)
                      _badge(opportunity.location, AppTheme.success),
                    _badge('${opportunity.applicantCount} applicants',
                        AppTheme.accent),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
            onSelected: (val) async {
              if (val == 'close') {
                await ref
                    .read(opportunityRepositoryProvider)
                    .updateStatus(opportunity.id, OpportunityStatus.closed);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opportunity closed')),
                  );
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'close',
                child: Row(
                  children: [
                    Icon(Icons.close, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Close opportunity',
                        style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  String _commitmentLabel(CommitmentType c) {
    switch (c) {
      case CommitmentType.partTime:
        return 'Part-time';
      case CommitmentType.projectBased:
        return 'Project-based';
      case CommitmentType.flexible:
        return 'Flexible';
    }
  }
}
