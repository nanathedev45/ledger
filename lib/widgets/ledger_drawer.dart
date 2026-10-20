// lib/widgets/ledger_drawer.dart
//
// Shared app drawer. Shows every top-level screen and highlights the
// current one. Pure navigation.

import 'package:flutter/material.dart';

import '../navigation/screen_id.dart';
import '../screens/budget_screen.dart';
import '../screens/daily_report_screen.dart';
import '../screens/home_screen.dart';
import '../screens/monthly_report_screen.dart';
import '../screens/weekly_report_screen.dart';
import '../state/ledger_state.dart';

class LedgerDrawer extends StatelessWidget {
  final ScreenId current;
  final LedgerState ledger;

  const LedgerDrawer({
    Key? key,
    required this.current,
    required this.ledger,
  }) : super(key: key);

  void _go(BuildContext context, ScreenId target, Widget screen) {
    Navigator.of(context).pop(); // close the drawer
    if (target == current) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Text(
                'Ledger',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 1),
            _item(
              context,
              icon: Icons.account_balance_wallet_outlined,
              label: 'Home',
              target: ScreenId.home,
              screen: HomeScreen(ledger: ledger),
            ),
            _item(
              context,
              icon: Icons.pie_chart_outline,
              label: 'Budget',
              target: ScreenId.budget,
              screen: BudgetScreen(ledger: ledger),
            ),
            const Divider(height: 1),
            _item(
              context,
              icon: Icons.today_outlined,
              label: 'Daily Report',
              target: ScreenId.dailyReport,
              screen: DailyReportScreen(ledger: ledger),
            ),
            _item(
              context,
              icon: Icons.date_range_outlined,
              label: 'Weekly Report',
              target: ScreenId.weeklyReport,
              screen: WeeklyReportScreen(ledger: ledger),
            ),
            _item(
              context,
              icon: Icons.calendar_month_outlined,
              label: 'Monthly Report',
              target: ScreenId.monthlyReport,
              screen: MonthlyReportScreen(ledger: ledger),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(
      BuildContext context, {
        required IconData icon,
        required String label,
        required ScreenId target,
        required Widget screen,
      }) {
    final selected = target == current;
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: selected,
      selectedTileColor: Colors.blue.withOpacity(0.08),
      onTap: () => _go(context, target, screen),
    );
  }
}