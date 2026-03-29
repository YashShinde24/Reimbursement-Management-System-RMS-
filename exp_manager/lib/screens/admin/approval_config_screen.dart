import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/approval_flow.dart';
import '../../providers/approval_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../widgets/glass_card.dart';

class ApprovalConfigScreen extends StatefulWidget {
  const ApprovalConfigScreen({super.key});

  @override
  State<ApprovalConfigScreen> createState() => _ApprovalConfigScreenState();
}

class _ApprovalConfigScreenState extends State<ApprovalConfigScreen> {
  bool _isManagerFirst = true;
  final List<_StepConfig> _steps = [];
  String _ruleType = 'none';
  double _percentageThreshold = 60;
  String? _specificApproverId;

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final flow = context.read<ApprovalProvider>().approvalFlow;
      if (flow != null) {
        _isManagerFirst = flow.isManagerApproverFirst;
        _steps.clear();
        for (final step in flow.steps) {
          _steps.add(_StepConfig(
            approverId: step.approverId,
            label: step.label,
            role: step.approverRole,
          ));
        }
        if (flow.rule != null) {
          _ruleType = flow.rule!.type;
          _percentageThreshold = flow.rule!.percentageThreshold ?? 60;
          _specificApproverId = flow.rule!.specificApproverId;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = context.watch<UserProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final approvers = users.users
        .where((u) => u.role == 'manager' || u.role == 'admin')
        .toList();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF1A1A3E), const Color(0xFF0F0F23)]
              : [const Color(0xFFEEEBFF), const Color(0xFFF5F7FA)],
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text('Approval Configuration',
                    style: Theme.of(context).textTheme.headlineLarge),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Manager First Toggle
                  GlassCard(
                    child: SwitchListTile(
                      title: const Text('Manager Approves First'),
                      subtitle: const Text(
                          'Employee\'s manager is the first approver'),
                      value: _isManagerFirst,
                      onChanged: (v) =>
                          setState(() => _isManagerFirst = v),
                      activeColor: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Approval Steps
                  Text('Approval Steps',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    'Define the sequence of approvers for expense claims',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),

                  ..._steps.asMap().entries.map((entry) {
                    final i = entry.key;
                    final step = entry.value;
                    return GlassCard(
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(step.label,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                Text(
                                  users.getUserById(step.approverId)?.name ??
                                      'Unknown',
                                  style:
                                      Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          if (i > 0)
                            IconButton(
                              icon: const Icon(Icons.arrow_upward, size: 18),
                              onPressed: () {
                                setState(() {
                                  final item = _steps.removeAt(i);
                                  _steps.insert(i - 1, item);
                                });
                              },
                            ),
                          if (i < _steps.length - 1)
                            IconButton(
                              icon:
                                  const Icon(Icons.arrow_downward, size: 18),
                              onPressed: () {
                                setState(() {
                                  final item = _steps.removeAt(i);
                                  _steps.insert(i + 1, item);
                                });
                              },
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: AppTheme.errorColor),
                            onPressed: () {
                              setState(() => _steps.removeAt(i));
                            },
                          ),
                        ],
                      ),
                    );
                  }),

                  OutlinedButton.icon(
                    onPressed: () =>
                        _showAddStepDialog(context, approvers),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Step'),
                  ),
                  const SizedBox(height: 20),

                  // Conditional Rules
                  Text('Conditional Rules',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    'Define rules for auto-approval',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),

                  GlassCard(
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          title: const Text('No Conditional Rule'),
                          value: 'none',
                          groupValue: _ruleType,
                          onChanged: (v) =>
                              setState(() => _ruleType = v!),
                          activeColor: AppTheme.primaryColor,
                        ),
                        RadioListTile<String>(
                          title: const Text('Percentage Rule'),
                          subtitle: const Text(
                              'e.g., If 60% approve → auto-approved'),
                          value: AppConstants.rulePercentage,
                          groupValue: _ruleType,
                          onChanged: (v) =>
                              setState(() => _ruleType = v!),
                          activeColor: AppTheme.primaryColor,
                        ),
                        if (_ruleType == AppConstants.rulePercentage ||
                            _ruleType == AppConstants.ruleHybrid)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            child: Row(
                              children: [
                                const Text('Threshold: '),
                                Expanded(
                                  child: Slider(
                                    value: _percentageThreshold,
                                    min: 10,
                                    max: 100,
                                    divisions: 18,
                                    label:
                                        '${_percentageThreshold.round()}%',
                                    onChanged: (v) => setState(
                                        () => _percentageThreshold = v),
                                    activeColor: AppTheme.primaryColor,
                                  ),
                                ),
                                Text(
                                    '${_percentageThreshold.round()}%'),
                              ],
                            ),
                          ),
                        RadioListTile<String>(
                          title: const Text('Specific Approver Rule'),
                          subtitle: const Text(
                              'e.g., If CFO approves → auto-approved'),
                          value: AppConstants.ruleSpecificApprover,
                          groupValue: _ruleType,
                          onChanged: (v) =>
                              setState(() => _ruleType = v!),
                          activeColor: AppTheme.primaryColor,
                        ),
                        RadioListTile<String>(
                          title: const Text('Hybrid Rule'),
                          subtitle: const Text(
                              'Combine percentage + specific approver'),
                          value: AppConstants.ruleHybrid,
                          groupValue: _ruleType,
                          onChanged: (v) =>
                              setState(() => _ruleType = v!),
                          activeColor: AppTheme.primaryColor,
                        ),
                        if (_ruleType ==
                                AppConstants.ruleSpecificApprover ||
                            _ruleType == AppConstants.ruleHybrid)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: DropdownButtonFormField<String>(
                              value: _specificApproverId,
                              decoration: const InputDecoration(
                                labelText: 'Auto-Approve Approver',
                              ),
                              items: approvers.map((a) {
                                return DropdownMenuItem(
                                  value: a.id,
                                  child: Text('${a.name} (${a.role})'),
                                );
                              }).toList(),
                              onChanged: (v) => setState(
                                  () => _specificApproverId = v),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Save Configuration'),
                      onPressed: () => _save(context),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddStepDialog(
      BuildContext context, List<dynamic> approvers) {
    final labelCtrl = TextEditingController();
    String? selectedApproverId;
    String selectedRole = 'manager';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Approval Step'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Step Label',
                  hintText: 'e.g., Finance Review',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedApproverId,
                decoration: const InputDecoration(
                    labelText: 'Approver'),
                items: approvers.map<DropdownMenuItem<String>>((a) {
                  return DropdownMenuItem(
                    value: a.id,
                    child: Text('${a.name} (${a.role})'),
                  );
                }).toList(),
                onChanged: (v) =>
                    setDialogState(() => selectedApproverId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration:
                    const InputDecoration(labelText: 'Approver Role'),
                items: const [
                  DropdownMenuItem(
                      value: 'manager', child: Text('Manager')),
                  DropdownMenuItem(
                      value: 'finance', child: Text('Finance')),
                  DropdownMenuItem(
                      value: 'director', child: Text('Director')),
                  DropdownMenuItem(value: 'cfo', child: Text('CFO')),
                  DropdownMenuItem(value: 'ceo', child: Text('CEO')),
                ],
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedRole = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (labelCtrl.text.isNotEmpty &&
                    selectedApproverId != null) {
                  setState(() {
                    _steps.add(_StepConfig(
                      approverId: selectedApproverId!,
                      label: labelCtrl.text.trim(),
                      role: selectedRole,
                    ));
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final approvalProv = context.read<ApprovalProvider>();
    final existingFlow = approvalProv.approvalFlow;

    ApprovalRule? rule;
    if (_ruleType != 'none') {
      rule = ApprovalRule(
        type: _ruleType,
        percentageThreshold:
            (_ruleType == AppConstants.rulePercentage ||
                    _ruleType == AppConstants.ruleHybrid)
                ? _percentageThreshold
                : null,
        specificApproverId:
            (_ruleType == AppConstants.ruleSpecificApprover ||
                    _ruleType == AppConstants.ruleHybrid)
                ? _specificApproverId
                : null,
      );
    }

    final flow = ApprovalFlow(
      id: existingFlow?.id ?? const Uuid().v4(),
      companyId: auth.currentCompany!.id,
      isManagerApproverFirst: _isManagerFirst,
      steps: _steps.asMap().entries.map((entry) {
        return ApprovalFlowStep(
          sequence: entry.key,
          approverId: entry.value.approverId,
          approverRole: entry.value.role,
          label: entry.value.label,
        );
      }).toList(),
      rule: rule,
    );

    await approvalProv.saveApprovalFlow(flow);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Approval configuration saved!'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}

class _StepConfig {
  final String approverId;
  final String label;
  final String role;

  _StepConfig({
    required this.approverId,
    required this.label,
    required this.role,
  });
}
