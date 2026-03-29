import 'dart:convert';

class ApprovalFlow {
  final String id;
  final String companyId;
  final bool isManagerApproverFirst;
  final List<ApprovalFlowStep> steps;
  final ApprovalRule? rule;

  ApprovalFlow({
    required this.id,
    required this.companyId,
    this.isManagerApproverFirst = true,
    this.steps = const [],
    this.rule,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'companyId': companyId,
        'isManagerApproverFirst': isManagerApproverFirst,
        'steps': steps.map((s) => s.toMap()).toList(),
        'rule': rule?.toMap(),
      };

  factory ApprovalFlow.fromMap(Map<String, dynamic> map) => ApprovalFlow(
        id: map['id'],
        companyId: map['companyId'],
        isManagerApproverFirst: map['isManagerApproverFirst'] ?? true,
        steps: (map['steps'] as List?)
                ?.map((s) => ApprovalFlowStep.fromMap(s))
                .toList() ??
            [],
        rule:
            map['rule'] != null ? ApprovalRule.fromMap(map['rule']) : null,
      );

  String toJson() => json.encode(toMap());
  factory ApprovalFlow.fromJson(String source) =>
      ApprovalFlow.fromMap(json.decode(source));

  ApprovalFlow copyWith({
    bool? isManagerApproverFirst,
    List<ApprovalFlowStep>? steps,
    ApprovalRule? rule,
    bool clearRule = false,
  }) =>
      ApprovalFlow(
        id: id,
        companyId: companyId,
        isManagerApproverFirst:
            isManagerApproverFirst ?? this.isManagerApproverFirst,
        steps: steps ?? this.steps,
        rule: clearRule ? null : (rule ?? this.rule),
      );
}

class ApprovalFlowStep {
  final int sequence;
  final String approverId;
  final String approverRole; // 'manager', 'finance', 'director', etc.
  final String label; // Display name for the step

  ApprovalFlowStep({
    required this.sequence,
    required this.approverId,
    required this.approverRole,
    required this.label,
  });

  Map<String, dynamic> toMap() => {
        'sequence': sequence,
        'approverId': approverId,
        'approverRole': approverRole,
        'label': label,
      };

  factory ApprovalFlowStep.fromMap(Map<String, dynamic> map) =>
      ApprovalFlowStep(
        sequence: map['sequence'],
        approverId: map['approverId'],
        approverRole: map['approverRole'],
        label: map['label'],
      );
}

class ApprovalRule {
  final String type; // 'percentage', 'specific_approver', 'hybrid'
  final double? percentageThreshold; // e.g., 60.0 for 60%
  final String? specificApproverId; // auto-approve if this person approves

  ApprovalRule({
    required this.type,
    this.percentageThreshold,
    this.specificApproverId,
  });

  Map<String, dynamic> toMap() => {
        'type': type,
        'percentageThreshold': percentageThreshold,
        'specificApproverId': specificApproverId,
      };

  factory ApprovalRule.fromMap(Map<String, dynamic> map) => ApprovalRule(
        type: map['type'],
        percentageThreshold: map['percentageThreshold'] != null
            ? (map['percentageThreshold'] as num).toDouble()
            : null,
        specificApproverId: map['specificApproverId'],
      );
}
