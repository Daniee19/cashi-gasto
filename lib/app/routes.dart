import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/auth/onboarding_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/transactions/transaction_list_screen.dart';
import '../presentation/screens/transactions/add_transaction_screen.dart';
import '../presentation/screens/categories/categories_screen.dart';
import '../presentation/screens/funds/funds_screen.dart';
import '../presentation/screens/funds/transfer_fund_screen.dart';
import '../presentation/screens/goals/goals_screen.dart';
import '../presentation/screens/alerts/alerts_screen.dart';
import '../presentation/screens/reports/reports_screen.dart';
import '../presentation/screens/settings/sms_settings_screen.dart';
import '../presentation/screens/chat/chat_screen.dart';
import '../presentation/screens/addiction_support/addiction_support_screen.dart';
import '../presentation/screens/addiction_support/abstinence_tracker_screen.dart';
import '../presentation/screens/addiction_support/blocked_apps_screen.dart';
import '../presentation/screens/addiction_support/support_resources_screen.dart';

class AppRoutes {
  AppRoutes._();

  // Route names
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String transactions = '/transactions';
  static const String addTransaction = '/transactions/add';
  static const String categories = '/categories';
  static const String funds = '/funds';
  static const String transferFunds = '/funds/transfer';
  static const String budgets = '/budgets';
  static const String goals = '/goals';
  static const String alerts = '/alerts';
  static const String loans = '/loans';
  static const String reports = '/reports';
  static const String chatbot = '/chatbot';
  static const String settings = '/settings';
  static const String smsSettings = '/settings/sms-detection';
  static const String addictionSupport = '/addiction-support';
  static const String abstinenceTracker = '/addiction-support/tracker';
  static const String blockedApps = '/addiction-support/blocked-apps';
  static const String supportResources = '/addiction-support/resources';

  static final GoRouter router = GoRouter(
    initialLocation: login,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: transactions,
        name: 'transactions',
        builder: (context, state) => const TransactionListScreen(),
      ),
      GoRoute(
        path: addTransaction,
        name: 'addTransaction',
        builder: (context, state) => const AddTransactionScreen(),
      ),
      GoRoute(
        path: categories,
        name: 'categories',
        builder: (context, state) => const CategoriesScreen(),
      ),
      GoRoute(
        path: funds,
        name: 'funds',
        builder: (context, state) => const FundsScreen(),
      ),
      GoRoute(
        path: transferFunds,
        name: 'transferFunds',
        builder: (context, state) => const TransferFundScreen(),
      ),
      GoRoute(
        path: goals,
        name: 'goals',
        builder: (context, state) => const GoalsScreen(),
      ),
      GoRoute(
        path: alerts,
        name: 'alerts',
        builder: (context, state) => const AlertsScreen(),
      ),
      GoRoute(
        path: reports,
        name: 'reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: smsSettings,
        name: 'smsSettings',
        builder: (context, state) => const SmsSettingsScreen(),
      ),
      GoRoute(
        path: chatbot,
        name: 'chatbot',
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: addictionSupport,
        name: 'addictionSupport',
        builder: (context, state) => const AddictionSupportScreen(),
      ),
      GoRoute(
        path: abstinenceTracker,
        name: 'abstinenceTracker',
        builder: (context, state) => const AbstinenceTrackerScreen(),
      ),
      GoRoute(
        path: blockedApps,
        name: 'blockedApps',
        builder: (context, state) => const BlockedAppsScreen(),
      ),
      GoRoute(
        path: supportResources,
        name: 'supportResources',
        builder: (context, state) => const SupportResourcesScreen(),
      ),
      // TODO: Add remaining routes as screens are implemented
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
  );
}
