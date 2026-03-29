import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/approval_flow.dart';
import '../models/approval_step.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class ApprovalProvider extends ChangeNotifier {
  ApprovalFlow? _approvalFlow;
  List<ApprovalStepRecord> _stepRecords = [];
  bool _isLoading = false;
  final _uuid = const Uuid();

  ApprovalFlow? get approvalFlow => _approvalFlow;
  List<ApprovalStepRecord> get stepRecords => _stepRecords;
  bool get isLoading => _isLoading;

  // Get pending approvals for a specific approver
  List<ApprovalStepRecord> getPendingForApprover(String approverId) =>
      _stepRecords
          .where((s) => s.approverId == approverId && s.isPending)
          .toList();

  // Get all step records for a specific expense
  List<ApprovalStepRecord> getStepsForExpense(String expenseId) =>
      _stepRecords
          .where((s) => s.expenseId == expenseId)
          .toList()
        ..sort((a, b) => a.sequence.compareTo(b.sequence));

  Future<void> loadApprovalFlow(String companyId) async {
    _isLoading = true;
    notifyListeners();

    final storage = await StorageService.getInstance();

    // Load approval flow
    final flows = await storage.getList(AppConstants.keyApprovalFlows);
    try {
      final flowData =
          flows.firstWhere((f) => f['companyId'] == companyId);
      _approvalFlow = ApprovalFlow.fromMap(flowData);
    } catch (_) {
      _approvalFlow = null;
    }

    // Load step records
    final records = await storage.getList(AppConstants.keyApprovalSteps);
    _stepRecords =
        records.map((r) => ApprovalStepRecord.fromMap(r)).toList();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveApprovalFlow(ApprovalFlow flow) async {
    final storage = await StorageService.getInstance();

    if (_approvalFlow != null) {
      await storage.updateInList(AppConstants.keyApprovalFlows, 'id',
          flow.id, flow.toMap());
    } else {
      await storage.addToList(
          AppConstants.keyApprovalFlows, flow.toMap());
    }

    _approvalFlow = flow;
    notifyListeners();
  }

  /// Create approval step records when an expense is submitted
  Future<void> createApprovalSteps({
    required String expenseId,
    required String submitterId,
    required String? managerIdOfSubmitter,
  }) async {
    final storage = await StorageService.getInstance();
    int sequenceStart = 1;

    // If no approval flow is configured, create a default single-step
    // approval assigned to the employee's manager
    if (_approvalFlow == null) {
      if (managerIdOfSubmitter != null) {
        final managerStep = ApprovalStepRecord(
          id: _uuid.v4(),
          expenseId: expenseId,
          approverId: managerIdOfSubmitter,
          sequence: 1,
          status: AppConstants.statusPending,
        );
        _stepRecords.add(managerStep);
        await storage.addToList(
            AppConstants.keyApprovalSteps, managerStep.toMap());
      }
      notifyListeners();
      return;
    }

    // If "Is Manager Approver First" is checked and employee has a manager
    if (_approvalFlow!.isManagerApproverFirst &&
        managerIdOfSubmitter != null) {
      final managerStep = ApprovalStepRecord(
        id: _uuid.v4(),
        expenseId: expenseId,
        approverId: managerIdOfSubmitter,
        sequence: 1,
        status: AppConstants.statusPending,
      );
      _stepRecords.add(managerStep);
      await storage.addToList(
          AppConstants.keyApprovalSteps, managerStep.toMap());
      sequenceStart = 2;
    }

    // Add configured flow steps
    for (final step in _approvalFlow!.steps) {
      // Don't duplicate the manager if already added above
      if (_approvalFlow!.isManagerApproverFirst &&
          managerIdOfSubmitter != null &&
          step.approverId == managerIdOfSubmitter) {
        continue;
      }

      final record = ApprovalStepRecord(
        id: _uuid.v4(),
        expenseId: expenseId,
        approverId: step.approverId,
        sequence: sequenceStart + step.sequence,
        // Only the first step (or step after manager) should be pending;
        // others wait
        status: sequenceStart == 1 && step.sequence == 0
            ? AppConstants.statusPending
            : 'waiting',
      );
      _stepRecords.add(record);
      await storage.addToList(
          AppConstants.keyApprovalSteps, record.toMap());
      sequenceStart++;
    }

    // If no flow steps are configured, set first step as active
    final expenseSteps = getStepsForExpense(expenseId);
    if (expenseSteps.isNotEmpty &&
        expenseSteps.every((s) => s.status == 'waiting')) {
      await _activateStep(expenseSteps.first.id);
    }

    notifyListeners();
  }

  Future<void> _activateStep(String stepId) async {
    final index = _stepRecords.indexWhere((s) => s.id == stepId);
    if (index == -1) return;

    _stepRecords[index] = _stepRecords[index].copyWith(
      status: AppConstants.statusPending,
    );

    final storage = await StorageService.getInstance();
    await storage.updateInList(AppConstants.keyApprovalSteps, 'id',
        stepId, _stepRecords[index].toMap());
  }

  /// Approve or reject a step. Returns the new expense status if flow is complete
  Future<String?> processApproval({
    required String stepId,
    required String status, // 'approved' or 'rejected'
    String? comments,
  }) async {
    final index = _stepRecords.indexWhere((s) => s.id == stepId);
    if (index == -1) return null;

    final step = _stepRecords[index];
    _stepRecords[index] = step.copyWith(
      status: status,
      comments: comments,
      decidedAt: DateTime.now(),
    );

    final storage = await StorageService.getInstance();
    await storage.updateInList(AppConstants.keyApprovalSteps, 'id',
        stepId, _stepRecords[index].toMap());

    final expenseSteps = getStepsForExpense(step.expenseId);

    // If rejected, the expense is rejected
    if (status == AppConstants.statusRejected) {
      // Check conditional rules
      final ruleResult =
          _evaluateConditionalRules(expenseSteps, step.approverId);
      if (ruleResult != null) {
        notifyListeners();
        return ruleResult;
      }

      notifyListeners();
      return AppConstants.statusRejected;
    }

    // If approved, check conditional rules first
    if (status == AppConstants.statusApproved) {
      final ruleResult =
          _evaluateConditionalRules(expenseSteps, step.approverId);
      if (ruleResult != null) {
        notifyListeners();
        return ruleResult;
      }

      // Check if all steps are done
      final allDecided = expenseSteps.every(
          (s) => s.status == 'approved' || s.status == 'rejected');
      if (allDecided) {
        notifyListeners();
        return AppConstants.statusApproved;
      }

      // Activate next waiting step
      final nextStep = expenseSteps
          .where((s) => s.status == 'waiting')
          .toList();
      if (nextStep.isNotEmpty) {
        await _activateStep(nextStep.first.id);
      }
    }

    notifyListeners();
    return null; // Flow still in progress
  }

  String? _evaluateConditionalRules(
      List<ApprovalStepRecord> steps, String currentApproverId) {
    if (_approvalFlow?.rule == null) return null;

    final rule = _approvalFlow!.rule!;
    final decidedSteps = steps.where(
        (s) => s.status == 'approved' || s.status == 'rejected');
    final approvedSteps =
        steps.where((s) => s.status == 'approved');

    switch (rule.type) {
      case AppConstants.rulePercentage:
        if (rule.percentageThreshold != null && steps.isNotEmpty) {
          final approvePercent =
              (approvedSteps.length / steps.length) * 100;
          if (approvePercent >= rule.percentageThreshold!) {
            return AppConstants.statusApproved;
          }
          // Check if it's impossible to reach threshold
          final remainingSteps = steps.length - decidedSteps.length;
          final maxPossibleApproves =
              approvedSteps.length + remainingSteps;
          final maxPercent = (maxPossibleApproves / steps.length) * 100;
          if (maxPercent < rule.percentageThreshold!) {
            return AppConstants.statusRejected;
          }
        }
        break;

      case AppConstants.ruleSpecificApprover:
        if (rule.specificApproverId == currentApproverId) {
          // Check current step's decision
          final currentStep = steps.firstWhere(
              (s) => s.approverId == currentApproverId,
              orElse: () => steps.first);
          if (currentStep.status == 'approved') {
            return AppConstants.statusApproved;
          }
        }
        break;

      case AppConstants.ruleHybrid:
        // Specific approver auto-approves
        if (rule.specificApproverId == currentApproverId) {
          final currentStep = steps.firstWhere(
              (s) => s.approverId == currentApproverId,
              orElse: () => steps.first);
          if (currentStep.status == 'approved') {
            return AppConstants.statusApproved;
          }
        }
        // OR percentage threshold
        if (rule.percentageThreshold != null && steps.isNotEmpty) {
          final approvePercent =
              (approvedSteps.length / steps.length) * 100;
          if (approvePercent >= rule.percentageThreshold!) {
            return AppConstants.statusApproved;
          }
        }
        break;
    }

    return null;
  }
}
