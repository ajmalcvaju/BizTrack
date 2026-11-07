class AppConstants {
  static const String appName = 'Bizora';
  static const String appTagline = 'Smart Business Manager';
  static const String currencySymbol = '₹';
  static const String currencyCode = 'INR';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String leadsCollection = 'leads';
  static const String customersCollection = 'customers';
  static const String paymentsCollection = 'payments';
  static const String monthlyTargetsCollection = 'monthlyTargets';
  static const String expensesCollection = 'expenses';
  static const String futureExpensesCollection = 'futureExpenses';
  static const String tasksCollection = 'tasks';
  static const String transfersCollection = 'transfers';

  // Account Types (Bank vs Cash vs Father's Account)
  static const String accountTypeCash = 'Cash';
  static const String accountTypeBank = 'Bank';
  static const String accountTypeFatherBank = "Father's Account";
  static const List<String> accountTypes = [
    accountTypeBank,
    accountTypeCash,
    accountTypeFatherBank,
  ];

  // Lead Response Statuses
  static const String leadStatusFollowUp = 'Follow Up';
  static const String leadStatusInterested = 'Interested';
  static const String leadStatusDNP = 'DNP';
  static const List<String> leadStatuses = [
    leadStatusFollowUp,
    leadStatusInterested,
    leadStatusDNP,
  ];

  // Customer Work Statuses
  static const String workStatusNotStarted = 'Not Started';
  static const String workStatusInProgress = 'In Progress';
  static const String workStatusInReview = 'In Review';
  static const String workStatusOnHold = 'On Hold';
  static const String workStatusCompleted = 'Completed';
  static const String workStatusCancelled = 'Cancelled';
  static const List<String> workStatuses = [
    workStatusNotStarted,
    workStatusInProgress,
    workStatusInReview,
    workStatusOnHold,
    workStatusCompleted,
    workStatusCancelled,
  ];

  // Payment Methods
  static const String paymentMethodCash = 'Cash';
  static const String paymentMethodUPI = 'UPI';
  static const String paymentMethodBankTransfer = 'Bank Transfer';
  static const String paymentMethodOther = 'Other';
  static const List<String> paymentMethods = [
    paymentMethodCash,
    paymentMethodUPI,
    paymentMethodBankTransfer,
    paymentMethodOther,
  ];

  // Expense Categories
  static const String expenseCategorySalary = 'Salary';
  static const String expenseCategoryPersonal = 'Personal Expense';
  static const String expenseCategoryOther = 'Other Expense';
  static const List<String> expenseCategories = [
    expenseCategorySalary,
    expenseCategoryPersonal,
    expenseCategoryOther,
  ];

  // Future Expense Payment Statuses
  static const String futureExpenseStatusPending = 'Pending';
  static const String futureExpenseStatusPaid = 'Paid';

  // Task Priorities
  static const String priorityLow = 'Low';
  static const String priorityMedium = 'Medium';
  static const String priorityHigh = 'High';
  static const List<String> taskPriorities = [
    priorityLow,
    priorityMedium,
    priorityHigh,
  ];

  // Task Statuses
  static const String taskStatusPending = 'Pending';
  static const String taskStatusCompleted = 'Completed';
}
