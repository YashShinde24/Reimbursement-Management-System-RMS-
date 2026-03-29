class AppConstants {
  static const String appName = 'ExpenseFlow';

  // API URLs
  static const String countriesApi =
      'https://restcountries.com/v3.1/all?fields=name,currencies';
  static String exchangeRateApi(String base) =>
      'https://api.exchangerate-api.com/v4/latest/$base';

  // Expense Categories
  static const List<String> expenseCategories = [
    'Travel',
    'Food & Dining',
    'Accommodation',
    'Transportation',
    'Office Supplies',
    'Software & Tools',
    'Training & Education',
    'Client Entertainment',
    'Communication',
    'Medical',
    'Miscellaneous',
  ];

  // User Roles
  static const String roleAdmin = 'admin';
  static const String roleManager = 'manager';
  static const String roleEmployee = 'employee';

  // Expense Statuses
  static const String statusPending = 'pending';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';
  static const String statusInReview = 'in_review';

  // Approval Rule Types
  static const String rulePercentage = 'percentage';
  static const String ruleSpecificApprover = 'specific_approver';
  static const String ruleHybrid = 'hybrid';

  // Storage Keys
  static const String keyCompanies = 'companies';
  static const String keyUsers = 'users';
  static const String keyExpenses = 'expenses';
  static const String keyApprovalFlows = 'approval_flows';
  static const String keyApprovalSteps = 'approval_steps';
  static const String keyCurrentUser = 'current_user';
  static const String keyCountriesCache = 'countries_cache';
}
