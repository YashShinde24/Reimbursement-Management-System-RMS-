import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/expense.dart';
import '../../providers/approval_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../services/currency_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../widgets/glass_card.dart';

class SubmitExpenseScreen extends StatefulWidget {
  const SubmitExpenseScreen({super.key});
  @override
  State<SubmitExpenseScreen> createState() => _SubmitExpenseScreenState();
}

class _SubmitExpenseScreenState extends State<SubmitExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _vendorCtrl = TextEditingController();

  final _lineDescCtrl = TextEditingController();
  final _lineAmountCtrl = TextEditingController();

  String _category = AppConstants.expenseCategories.first;
  String _currency = 'USD';
  DateTime _date = DateTime.now();
  final List<ExpenseLine> _expenseLines = [];
  bool _isSubmitting = false;
  List<String> _currencies = [];

  @override
  void initState() {
    super.initState();
    _loadCurrencies();
  }

  Future<void> _loadCurrencies() async {
    final countries = await CurrencyService().getCountries();
    final codes = countries.map((c) => c.currencyCode).toSet().toList()..sort();
    if (mounted) {
      setState(() {
        _currencies = codes;
        final auth = context.read<AuthProvider>();
        _currency = auth.currentCompany?.currencyCode ?? 'USD';
      });
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _vendorCtrl.dispose();

    _lineDescCtrl.dispose();
    _lineAmountCtrl.dispose();
    super.dispose();
  }

  double get _totalAmount =>
      _expenseLines.fold(0.0, (sum, line) => sum + line.amount);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF1A1A3E), const Color(0xFF0F0F23)]
              : [const Color(0xFFEEEBFF), const Color(0xFFF5F7FA)],
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(children: [
                Expanded(child: Text('Submit Expense',
                    style: Theme.of(context).textTheme.headlineLarge)),
              ]),
            )),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(delegate: SliverChildListDelegate([
                _buildMainForm(),
              ])),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildMainForm() {
    return GlassCard(padding: const EdgeInsets.all(20), child: Form(
      key: _formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Currency selector
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(
            value: _currencies.contains(_currency)
                ? _currency
                : (_currencies.isNotEmpty ? _currencies.first : null),
            decoration: const InputDecoration(labelText: 'Expense Currency', prefixIcon: Icon(Icons.currency_exchange, size: 20)),
            isExpanded: true,
            items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) { if (v != null) setState(() => _currency = v); },
          )),
        ]),
        const SizedBox(height: 14),

        // Category
        DropdownButtonFormField<String>(
          value: _category,
          decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_outlined, size: 20)),
          items: AppConstants.expenseCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) { if (v != null) setState(() => _category = v); },
        ),
        const SizedBox(height: 14),

        // Description
        TextFormField(controller: _descCtrl, maxLines: 3,
            decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description_outlined, size: 20), alignLabelWithHint: true),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null),
        const SizedBox(height: 14),

        // Vendor
        TextFormField(controller: _vendorCtrl,
            decoration: const InputDecoration(labelText: 'Vendor / Restaurant Name', prefixIcon: Icon(Icons.store_outlined, size: 20))),
        const SizedBox(height: 14),

        // Date
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
          title: Text(DateFormat('MMM dd, yyyy').format(_date)),
          subtitle: const Text('Expense Date'),
          trailing: OutlinedButton(onPressed: () => _pickDate(context), child: const Text('Change')),
        ),
        const Divider(height: 28),

        // === EXPENSE ITEMS SECTION ===
        Row(children: [
          const Icon(Icons.receipt_long, color: AppTheme.primaryColor, size: 22),
          const SizedBox(width: 8),
          Expanded(child: Text('Expense Items', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700))),
          if (_expenseLines.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('${_expenseLines.length} items',
                  style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 12)),
            ),
        ]),
        const SizedBox(height: 4),
        Text('Add one or more items to this expense claim.',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),

        // List of added items
        if (_expenseLines.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
            ),
            child: Row(children: [
              Icon(Icons.info_outline, size: 18, color: Colors.grey.withValues(alpha: 0.5)),
              const SizedBox(width: 8),
              Text('No items added yet. Add at least one item.',
                  style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),

        ..._expenseLines.asMap().entries.map((e) => Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
          ),
          child: Row(children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(child: Text('${e.key + 1}',
                  style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w700, fontSize: 12))),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(e.value.description, style: Theme.of(context).textTheme.bodyMedium)),
            Text('$_currency ${e.value.amount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            IconButton(
              icon: const Icon(Icons.close, size: 16, color: AppTheme.errorColor),
              onPressed: () => setState(() => _expenseLines.removeAt(e.key)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            ),
          ]),
        )),
        const SizedBox(height: 8),

        // Add item row
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
          ),
          child: Column(children: [
            Column(children: [
              TextField(
                controller: _lineDescCtrl,
                decoration: const InputDecoration(hintText: 'Item description', isDense: true, prefixIcon: Icon(Icons.edit, size: 16)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _lineAmountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(hintText: 'Amount', isDense: true, prefixIcon: Icon(Icons.attach_money, size: 16)),
              ),
            ]),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(
              icon: const Icon(Icons.add_circle, size: 18),
              label: const Text('Add Item'),
              onPressed: _addLine,
            )),
          ]),
        ),

        // Total
        if (_expenseLines.isNotEmpty) ...[
          const Divider(height: 28),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Total', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            Text('$_currency ${_totalAmount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800, color: AppTheme.primaryColor)),
          ]),
        ],

        const SizedBox(height: 24),

        // Submit
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(
          icon: _isSubmitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.send),
          label: Text(_isSubmitting ? 'Submitting...' : 'Submit Expense'),
          onPressed: _isSubmitting ? null : _submit,
        )),
      ]),
    ));
  }


  void _addLine() {
    final desc = _lineDescCtrl.text.trim();
    final amt = double.tryParse(_lineAmountCtrl.text.trim());
    if (desc.isEmpty || amt == null || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please enter both item description and a valid amount'),
        backgroundColor: AppTheme.warningColor,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() {
      _expenseLines.add(ExpenseLine(description: desc, amount: amt));
      _lineDescCtrl.clear();
      _lineAmountCtrl.clear();
    });
  }

  Future<void> _pickDate(BuildContext ctx) async {
    final picked = await showDatePicker(context: ctx, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now());
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_expenseLines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please add at least one expense item'),
        backgroundColor: AppTheme.warningColor,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _isSubmitting = true);
    final auth = context.read<AuthProvider>();
    final expProv = context.read<ExpenseProvider>();
    final approvalProv = context.read<ApprovalProvider>();

    final expense = await expProv.submitExpense(
      amount: _totalAmount,
      currencyCode: _currency, category: _category,
      description: _descCtrl.text.trim(), date: _date,
      submittedById: auth.currentUser!.id,
      companyId: auth.currentCompany!.id,
      companyCurrencyCode: auth.currentCompany!.currencyCode,
      expenseLines: List<ExpenseLine>.from(_expenseLines),
      vendorName: _vendorCtrl.text.trim().isEmpty ? null : _vendorCtrl.text.trim(),
    );

    await approvalProv.createApprovalSteps(
      expenseId: expense.id,
      submitterId: auth.currentUser!.id,
      managerIdOfSubmitter: auth.currentUser!.managerId,
    );

    setState(() => _isSubmitting = false);
    _descCtrl.clear(); _vendorCtrl.clear();
    setState(() {
      _expenseLines.clear();
      _date = DateTime.now();
      _category = AppConstants.expenseCategories.first;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Expense submitted successfully!'),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}
