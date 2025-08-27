// lib/main.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Ensure these paths are correct and files exist
import 'package:finance_tracker/screens/home_screen.dart';
import 'package:finance_tracker/screens/transfer_screen.dart';
import 'package:finance_tracker/screens/analytics_screen.dart';
import 'package:finance_tracker/screens/reminder_screen.dart';
import 'package:finance_tracker/screens/add_transaction_screen.dart';
import 'package:finance_tracker/utils/colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.accentGreen,
        hintColor: AppColors.accentGreen,
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ).copyWith(
          bodyLarge: const TextStyle(color: AppColors.primaryText, fontSize: 16),
          bodyMedium: const TextStyle(color: AppColors.secondaryText, fontSize: 14),
          titleLarge: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 28),
          titleMedium: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w600, fontSize: 18),
          labelLarge: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          displaySmall: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 36),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.primaryText),
          titleTextStyle: GoogleFonts.inter(
            color: AppColors.primaryText,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 1.5,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          color: AppColors.cardBackground,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.cardBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: AppColors.accentGreen, width: 1.5),
          ),
          hintStyle: TextStyle(color: AppColors.secondaryText.withOpacity(0.7)),
          labelStyle: const TextStyle(color: AppColors.primaryText),
          contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.0),
            ),
            elevation: 2,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accentGreen,
              side: const BorderSide(color: AppColors.accentGreen, width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
            )
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.cardBackground,
          selectedItemColor: AppColors.accentGreen,
          unselectedItemColor: AppColors.secondaryText.withOpacity(0.7),
          selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.accentGreen,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: CircleBorder(),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accentGreen,
          background: AppColors.background,
          surface: AppColors.cardBackground,
          primary: AppColors.accentGreen,
          secondary: AppColors.accentLightGreen,
        ).copyWith(error: AppColors.expenseColor),
      ),
      home: const MainAppScreen(),
    );
  }
}

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _selectedIndex = 0;
  late List<Widget> _widgetOptionsWithCallback;

  // Method to change tab, can be called from child widgets via callback
  void _changeTab(int index) {
    if (index >= 0 && index < _widgetOptionsWithCallback.length && index != 2) {
      if (mounted) {
        setState(() {
          _selectedIndex = index;
        });
      }
    }
  }

  // Generate widget options, passing the callback to HomeScreen
  List<Widget> _generateWidgetOptions(Function(int) onTabChange) {
    return <Widget>[
      // Pass the callback to HomeScreen. HomeScreen's constructor needs to accept it.
      HomeScreen(onNavigateToTransferTab: () => onTabChange(1)), // Index 0
      const TransferScreen(),                                    // Index 1
      const SizedBox.shrink(),                                   // Index 2 (FAB placeholder)
      const AnalyticsScreen(),                                   // Index 3
      const ReminderScreen(),                                    // Index 4
    ];
  }

  @override
  void initState() {
    super.initState();
    _widgetOptionsWithCallback = _generateWidgetOptions(_changeTab);
  }

  void _onItemTapped(int index) { // This method is for the BottomAppBar items
    if (index == 2) return; // Index 2 is the FAB placeholder
    if (mounted) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _navigateToAddTransaction() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
    );

    if (result == true && mounted) {
      print("Transaction added/edited. Active screen index: $_selectedIndex.");
      // The active screen (e.g., HomeScreen) should ideally refresh itself
      // if it's visible. This can be done by it re-fetching data in its `initState`
      // if it's popped and re-pushed, or via pull-to-refresh, or by listening
      // to a global state change (using Provider, Riverpod, etc.).
      // Directly calling a method on a child's private state is not robust.
      // We will rely on HomeScreen's own refresh mechanisms for now.
      // If HomeScreen is currently active, it might need a manual pull-to-refresh
      // or it should re-fetch data if its state is preserved and it becomes visible again.
      if (_selectedIndex == 0) {
        // If you absolutely need to trigger HomeScreen's refresh and it has a public method
        // via its State class (and you have a key to it), you could.
        // But it's better for HomeScreen to manage its own refresh when it becomes active
        // or when data it depends on changes (via state management).
        print("HomeScreen is active. It should ideally refresh its data if needed.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptionsWithCallback,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddTransaction,
        child: const Icon(Icons.add, size: 30),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        elevation: 10,
        color: AppColors.cardBackground,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _buildNavItem(icon: Icons.home_rounded, label: 'Home', index: 0),
              _buildNavItem(icon: Icons.swap_horiz_rounded, label: 'Transfer', index: 1),
              const SizedBox(width: 48),
              _buildNavItem(icon: Icons.bar_chart_rounded, label: 'Analytics', index: 3),
              _buildNavItem(icon: Icons.notifications_active_outlined, label: 'Reminder', index: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index}) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onItemTapped(index), // Correctly calls the method in this class
          borderRadius: BorderRadius.circular(24),
          splashColor: AppColors.accentGreen.withOpacity(0.1),
          highlightColor: AppColors.accentGreen.withOpacity(0.05),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                color: isSelected ? AppColors.accentGreen : AppColors.secondaryText.withOpacity(0.8),
                size: isSelected ? 28 : 26,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.accentGreen : AppColors.secondaryText.withOpacity(0.8),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}