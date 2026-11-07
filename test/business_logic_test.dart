import 'package:flutter_test/flutter_test.dart';
import 'package:bizpilot/core/utils/currency_formatter.dart';
import 'package:bizpilot/core/utils/date_formatter.dart';
import 'package:bizpilot/features/leads/models/lead_model.dart';
import 'package:bizpilot/features/customers/models/customer_model.dart';
import 'package:bizpilot/features/customers/models/payment_model.dart';
import 'package:bizpilot/features/payments/models/expense_model.dart';
import 'package:bizpilot/features/day_planner/models/task_model.dart';
import 'package:bizpilot/features/payments/models/future_expense_model.dart';
import 'package:bizpilot/core/constants/app_constants.dart';

void main() {
  group('1. Currency & Integer Paise Calculations', () {
    test('Converts rupees to paise accurately without floating point error', () {
      expect(CurrencyFormatter.toPaise(100), equals(10000));
      expect(CurrencyFormatter.toPaise(1250.50), equals(125050));
      expect(CurrencyFormatter.toPaise(0.99), equals(99));
    });

    test('Converts paise to rupees accurately', () {
      expect(CurrencyFormatter.toRupees(10000), equals(100.0));
      expect(CurrencyFormatter.toRupees(125050), equals(1250.50));
    });

    test('Parses rupee text string into integer paise', () {
      expect(CurrencyFormatter.parseRupeesToPaise('₹ 1,500'), equals(150000));
      expect(CurrencyFormatter.parseRupeesToPaise('50000.75'), equals(5000075));
      expect(CurrencyFormatter.parseRupeesToPaise(''), equals(0));
    });

    test('Formats currency with Indian Rupee symbol', () {
      final formatted = CurrencyFormatter.formatPaise(12500000); // ₹1,25,000
      expect(formatted.contains('₹'), isTrue);
      expect(formatted.contains('1,25,000'), isTrue);
    });
  });

  group('2. Date & Time Format Rules', () {
    test('Formats dates in DD-MM-YYYY format', () {
      final testDate = DateTime(2026, 11, 4);
      expect(DateFormatter.formatDate(testDate), equals('04-11-2026'));
    });

    test('Formats time in 12-hour format with AM/PM', () {
      final afternoonTime = DateTime(2026, 11, 4, 14, 30);
      expect(DateFormatter.formatTime(afternoonTime), equals('02:30 PM'));

      final morningTime = DateTime(2026, 11, 4, 9, 15);
      expect(DateFormatter.formatTime(morningTime), equals('09:15 AM'));
    });

    test('Detects past date for overdue calculation', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 1));
      final futureDate = DateTime.now().add(const Duration(days: 1));
      final today = DateTime.now();

      expect(DateFormatter.isPastDate(pastDate), isTrue);
      expect(DateFormatter.isPastDate(futureDate), isFalse);
      expect(DateFormatter.isPastDate(today), isFalse);
    });
  });

  group('3. Customer Balance & Payment Logic', () {
    test('Calculates balance = totalWorkAmount - totalAmountReceived', () {
      final customer = CustomerModel(
        id: 'cust-test',
        shopName: 'Super Mart',
        customerName: 'Aarav Patel',
        totalWorkAmount: 10000000, // ₹1,00,000
        totalAmountReceived: 4000000, // ₹40,000
        createdAt: DateTime.now(),
      );

      expect(customer.balanceAmount, equals(6000000)); // ₹60,000
      expect(customer.hasOutstanding, isTrue);
      expect(customer.isAdvanceOrSettled, isFalse);
    });

    test('Settled customer when balance is zero or excess', () {
      final settledCustomer = CustomerModel(
        id: 'cust-settled',
        shopName: 'Green Grocers',
        customerName: 'Sneha Roy',
        totalWorkAmount: 5000000,
        totalAmountReceived: 5000000,
        createdAt: DateTime.now(),
      );

      expect(settledCustomer.balanceAmount, equals(0));
      expect(settledCustomer.hasOutstanding, isFalse);
      expect(settledCustomer.isAdvanceOrSettled, isTrue);
    });
  });

  group('4. Lead Follow-up Logic', () {
    test('Upcoming lead when follow-up moment is in future', () {
      final upcomingLead = LeadModel(
        id: 'l-1',
        shopName: 'Kiran Cloth Store',
        customerName: 'Kiran',
        createdAt: DateTime.now(),
        nextFollowUpDate: DateTime.now().add(const Duration(days: 2)),
        nextFollowUpTime: '02:00 PM',
      );

      expect(upcomingLead.isUpcoming, isTrue);
      expect(upcomingLead.isDue, isFalse);
    });

    test('Due lead when follow-up moment is in past or due today', () {
      final dueLead = LeadModel(
        id: 'l-2',
        shopName: 'Raj Auto',
        customerName: 'Raj',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        nextFollowUpDate: DateTime.now().subtract(const Duration(days: 1)),
        nextFollowUpTime: '10:00 AM',
      );

      expect(dueLead.isDue, isTrue);
      expect(dueLead.isUpcoming, isFalse);
    });

    test('Active lead has no follow-up scheduled', () {
      final activeLead = LeadModel(
        id: 'l-3',
        shopName: 'Metro Books',
        customerName: 'Vikram',
        createdAt: DateTime.now(),
        nextFollowUpDate: null,
      );

      expect(activeLead.hasNoFollowUpScheduled, isTrue);
      expect(activeLead.isUpcoming, isFalse);
    });
  });

  group('5. Overdue Task Logic', () {
    test('Task is overdue from next day if not completed', () {
      final overdueTask = TaskModel(
        id: 't-1',
        title: 'GST Return Filing',
        taskDate: DateTime.now().subtract(const Duration(days: 1)),
        status: AppConstants.taskStatusPending,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      );

      expect(overdueTask.isOverdue, isTrue);
    });

    test('Completed task is not overdue even if past date', () {
      final completedTask = TaskModel(
        id: 't-2',
        title: 'Delivered Order #501',
        taskDate: DateTime.now().subtract(const Duration(days: 3)),
        status: AppConstants.taskStatusCompleted,
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
      );

      expect(completedTask.isOverdue, isFalse);
      expect(completedTask.isCompleted, isTrue);
    });
  });

  group('6. Overdue Future Expense Logic', () {
    test('Future expense is overdue if past scheduled date and pending', () {
      final overdueExpense = FutureExpenseModel(
        id: 'fe-1',
        title: 'Electricity Commercial Bill',
        amount: 800000,
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        paymentStatus: AppConstants.futureExpenseStatusPending,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      );

      expect(overdueExpense.isOverdue, isTrue);
      expect(overdueExpense.isPaid, isFalse);
    });

    test('Paid future expense is not overdue', () {
      final paidExpense = FutureExpenseModel(
        id: 'fe-2',
        title: 'Office Internet',
        amount: 150000,
        dueDate: DateTime.now().subtract(const Duration(days: 2)),
        paymentStatus: AppConstants.futureExpenseStatusPaid,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      );

      expect(paidExpense.isOverdue, isFalse);
      expect(paidExpense.isPaid, isTrue);
    });
  });

  group('7. Bank vs Cash Accounting & Liquid Balances', () {
    test('PaymentModel recognizes Cash vs Bank account type', () {
      final bankPayment = PaymentModel(
        id: 'p-bank',
        customerId: 'c-1',
        amountReceived: 2500000, // ₹25,000
        paymentDate: DateTime.now(),
        paymentMethod: AppConstants.paymentMethodUPI,
        accountType: AppConstants.accountTypeBank,
        remarks: 'Google Pay',
        createdAt: DateTime.now(),
      );

      final cashPayment = PaymentModel(
        id: 'p-cash',
        customerId: 'c-1',
        amountReceived: 1000000, // ₹10,000
        paymentDate: DateTime.now(),
        paymentMethod: AppConstants.paymentMethodCash,
        accountType: AppConstants.accountTypeCash,
        remarks: 'Counter cash',
        createdAt: DateTime.now(),
      );

      expect(bankPayment.isBank, isTrue);
      expect(bankPayment.isCash, isFalse);
      expect(cashPayment.isCash, isTrue);
      expect(cashPayment.isBank, isFalse);
    });

    test('PaymentModel legacy fallback resolves method Cash as Cash and others as Bank', () {
      final legacyCash = PaymentModel(
        id: 'p-leg-cash',
        customerId: 'c-1',
        amountReceived: 500000,
        paymentDate: DateTime.now(),
        paymentMethod: AppConstants.paymentMethodCash,
        remarks: 'Old cash record without accountType',
        createdAt: DateTime.now(),
      );

      final legacyBank = PaymentModel(
        id: 'p-leg-bank',
        customerId: 'c-1',
        amountReceived: 500000,
        paymentDate: DateTime.now(),
        paymentMethod: AppConstants.paymentMethodBankTransfer,
        remarks: 'Old bank transfer record without accountType',
        createdAt: DateTime.now(),
      );

      expect(legacyCash.isCash, isTrue);
      expect(legacyCash.accountType, equals(AppConstants.accountTypeCash));
      expect(legacyBank.isBank, isTrue);
      expect(legacyBank.accountType, equals(AppConstants.accountTypeBank));
    });

    test('ExpenseModel recognizes Cash vs Bank account type', () {
      final bankExpense = ExpenseModel(
        id: 'e-bank',
        title: 'Office Rent',
        amount: 1500000, // ₹15,000
        category: AppConstants.expenseCategoryOther,
        accountType: AppConstants.accountTypeBank,
        date: DateTime.now(),
        remarks: 'NEFT to Landlord',
        createdAt: DateTime.now(),
      );

      final cashExpense = ExpenseModel(
        id: 'e-cash',
        title: 'Office Refreshments',
        amount: 250000, // ₹2,500
        category: AppConstants.expenseCategoryPersonal,
        accountType: AppConstants.accountTypeCash,
        date: DateTime.now(),
        remarks: 'Cash petty expense',
        createdAt: DateTime.now(),
      );

      expect(bankExpense.isBank, isTrue);
      expect(bankExpense.isCash, isFalse);
      expect(cashExpense.isCash, isTrue);
      expect(cashExpense.isBank, isFalse);
    });

    test('Calculates exact Bank Balance, Cash Balance, and Total Liquid Balance', () {
      // Payments received (Money In)
      final payments = [
        PaymentModel(
          id: 'p1',
          customerId: 'c1',
          amountReceived: 5000000, // ₹50,000 in Bank
          paymentDate: DateTime.now(),
          paymentMethod: AppConstants.paymentMethodUPI,
          accountType: AppConstants.accountTypeBank,
          createdAt: DateTime.now(),
        ),
        PaymentModel(
          id: 'p2',
          customerId: 'c2',
          amountReceived: 2000000, // ₹20,000 in Cash
          paymentDate: DateTime.now(),
          paymentMethod: AppConstants.paymentMethodCash,
          accountType: AppConstants.accountTypeCash,
          createdAt: DateTime.now(),
        ),
        PaymentModel(
          id: 'p3',
          customerId: 'c3',
          amountReceived: 3000000, // ₹30,000 in Bank
          paymentDate: DateTime.now(),
          paymentMethod: AppConstants.paymentMethodBankTransfer,
          accountType: AppConstants.accountTypeBank,
          createdAt: DateTime.now(),
        ),
      ];

      // Expenses sent (Money Out)
      final expenses = [
        ExpenseModel(
          id: 'e1',
          title: 'Salary',
          amount: 2500000, // ₹25,000 from Bank
          category: AppConstants.expenseCategorySalary,
          accountType: AppConstants.accountTypeBank,
          date: DateTime.now(),
          createdAt: DateTime.now(),
        ),
        ExpenseModel(
          id: 'e2',
          title: 'Fuel & Snacks',
          amount: 500000, // ₹5,000 from Cash
          category: AppConstants.expenseCategoryPersonal,
          accountType: AppConstants.accountTypeCash,
          date: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      ];

      final bankReceived = payments.where((p) => p.isBank).fold(0, (sum, p) => sum + p.amountReceived);
      final cashReceived = payments.where((p) => p.isCash).fold(0, (sum, p) => sum + p.amountReceived);

      final bankSpent = expenses.where((e) => e.isBank).fold(0, (sum, e) => sum + e.amount);
      final cashSpent = expenses.where((e) => e.isCash).fold(0, (sum, e) => sum + e.amount);

      final bankBalance = bankReceived - bankSpent;
      final cashBalance = cashReceived - cashSpent;
      final totalLiquidBalance = bankBalance + cashBalance;

      // Bank: Received ₹80,000 (8,000,000 paise), Spent ₹25,000 (2,500,000 paise) -> Balance = ₹55,000 (5,500,000 paise)
      expect(bankReceived, equals(8000000));
      expect(bankSpent, equals(2500000));
      expect(bankBalance, equals(5500000));

      // Cash: Received ₹20,000 (2,000,000 paise), Spent ₹5,000 (500,000 paise) -> Balance = ₹15,000 (1,500,000 paise)
      expect(cashReceived, equals(2000000));
      expect(cashSpent, equals(500000));
      expect(cashBalance, equals(1500000));

      // Total Liquid = ₹55,000 + ₹15,000 = ₹70,000 (7,000,000 paise)
      expect(totalLiquidBalance, equals(7000000));
    });

    test('Father\'s Account recognition and cash transfer into Father\'s Account', () {
      final fatherPayment = PaymentModel(
        id: 'p-father',
        customerId: 'c-1',
        amountReceived: 1000000, // ₹10,000 received directly in father's bank
        paymentDate: DateTime.now(),
        accountType: AppConstants.accountTypeFatherBank,
        createdAt: DateTime.now(),
      );

      final fatherExpense = ExpenseModel(
        id: 'e-father',
        title: 'Electricity Bill',
        amount: 200000, // ₹2,000 paid from father's bank
        category: AppConstants.expenseCategoryOther,
        accountType: AppConstants.accountTypeFatherBank,
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );

      expect(fatherPayment.isFatherBank, isTrue);
      expect(fatherPayment.isBank, isFalse);
      expect(fatherPayment.isCash, isFalse);

      expect(fatherExpense.isFatherBank, isTrue);
      expect(fatherExpense.isBank, isFalse);
      expect(fatherExpense.isCash, isFalse);

      // Now test Transfer: Save cash in father's account
      // Cash starts at ₹15,000 (1,500,000 paise)
      // User transfers ₹5,000 (500,000 paise) cash to Father's Account
      int cashBalance = 1500000;
      int fatherBalance = 800000; // 1,000,000 - 200,000 = 800,000 paise (₹8,000)
      const transferAmount = 500000; // ₹5,000

      // Apply transfer: from Cash to Father's Account
      cashBalance -= transferAmount;
      fatherBalance += transferAmount;

      expect(cashBalance, equals(1000000)); // ₹10,000 left in cash
      expect(fatherBalance, equals(1300000)); // ₹13,000 in father's bank
      expect(cashBalance + fatherBalance, equals(2300000)); // Total sum unchanged
    });
  });
}
