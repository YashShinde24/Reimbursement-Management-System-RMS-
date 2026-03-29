import 'dart:convert';

class ApprovalStepRecord {
  final String id;
  final String expenseId;
  final String approverId;
  final int sequence;
  final String status; // 'pending', 'approved', 'rejected'
  final String? comments;
  final DateTime? decidedAt;
  final DateTime createdAt;

  ApprovalStepRecord({
    required this.id,
    required this.expenseId,
    required this.approverId,
    required this.sequence,
    this.status = 'pending',
    this.comments,
    this.decidedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  Map<String, dynamic> toMap() => {
        'id': id,
        'expenseId': expenseId,
        'approverId': approverId,
        'sequence': sequence,
        'status': status,
        'comments': comments,
        'decidedAt': decidedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory ApprovalStepRecord.fromMap(Map<String, dynamic> map) =>
      ApprovalStepRecord(
        id: map['id'],
        expenseId: map['expenseId'],
        approverId: map['approverId'],
        sequence: map['sequence'],
        status: map['status'] ?? 'pending',
        comments: map['comments'],
        decidedAt: map['decidedAt'] != null
            ? DateTime.parse(map['decidedAt'])
            : null,
        createdAt: DateTime.parse(map['createdAt']),
      );

  String toJson() => json.encode(toMap());
  factory ApprovalStepRecord.fromJson(String source) =>
      ApprovalStepRecord.fromMap(json.decode(source));

  ApprovalStepRecord copyWith({
    String? status,
    String? comments,
    DateTime? decidedAt,
  }) =>
      ApprovalStepRecord(
        id: id,
        expenseId: expenseId,
        approverId: approverId,
        sequence: sequence,
        status: status ?? this.status,
        comments: comments ?? this.comments,
        decidedAt: decidedAt ?? this.decidedAt,
        createdAt: createdAt,
      );
}
