import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/retail_provider.dart';
import '../billing/billing_screen.dart';
import '../customers/customers_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../inventory/inventory_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  void _onNavigateTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final retail = context.watch<RetailProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    final pages = [
      DashboardScreen(onNavigateTab: _onNavigateTab),
      const BillingScreen(),
      const InventoryScreen(),
      const CustomersScreen(),
      const ReportsScreen(),
      const SettingsScreen(),
    ];

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            // Desktop Left Sidebar (Executive Slate design)
            Container(
              width: 260,
              decoration: const BoxDecoration(
                color: AppTheme.cardSurface,
                border: Border(right: BorderSide(color: AppTheme.borderSlate)),
              ),
              child: Column(
                children: [
                  // Brand Header
                  Container(
                    height: 70,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppTheme.primarySlate,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rexon',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              Text(
                                auth.currentBusiness?.name ?? 'Retail Store',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Navigation Links
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      children: [
                        _buildNavItem(0, Icons.dashboard_rounded, 'Dashboard'),
                        _buildNavItem(1, Icons.point_of_sale_rounded, 'Fast Billing (POS)'),
                        _buildNavItem(
                          2,
                          Icons.inventory_2_rounded,
                          'Inventory',
                          badgeCount: retail.lowStockCount > 0 ? retail.lowStockCount : null,
                        ),
                        _buildNavItem(3, Icons.people_alt_rounded, 'Customers & Khata'),
                        _buildNavItem(4, Icons.bar_chart_rounded, 'Reports & Ledger'),
                        _buildNavItem(5, Icons.settings_rounded, 'Store Settings'),
                      ],
                    ),
                  ),

                  // User Profile & Role Footer
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: AppTheme.borderSlate)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppTheme.surfaceContainerLow,
                          child: Text(
                            auth.isOwner ? 'O' : 'S',
                            style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: AppTheme.secondaryBlue),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                auth.currentBusiness?.ownerName ?? 'Shop Owner',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                auth.isOwner ? 'Owner Mode' : 'Staff Mode',
                                style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout_rounded, size: 18, color: AppTheme.textMuted),
                          tooltip: 'Sign Out',
                          onPressed: () => auth.logout(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main Content Body
            Expanded(child: pages[_currentIndex]),
          ],
        ),
      );
    }

    // Mobile Viewport (Bottom Navigation)
    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.borderSlate)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onNavigateTab,
          backgroundColor: Colors.white,
          indicatorColor: AppTheme.secondaryBlue.withOpacity(0.12),
          destinations: [
            const NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
            const NavigationDestination(icon: Icon(Icons.point_of_sale_outlined), selectedIcon: Icon(Icons.point_of_sale_rounded), label: 'Billing'),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: retail.lowStockCount > 0,
                label: Text('${retail.lowStockCount}'),
                child: const Icon(Icons.inventory_2_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: retail.lowStockCount > 0,
                label: Text('${retail.lowStockCount}'),
                child: const Icon(Icons.inventory_2_rounded),
              ),
              label: 'Inventory',
            ),
            const NavigationDestination(icon: Icon(Icons.people_alt_outlined), selectedIcon: Icon(Icons.people_alt_rounded), label: 'Khata'),
            const NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart_rounded), label: 'Reports'),
            const NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: 'Settings'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, {int? badgeCount}) {
    final isSelected = _currentIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: () => _onNavigateTab(index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.surfaceContainerLow : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppTheme.secondaryBlue : AppTheme.textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppTheme.textDark : AppTheme.textSlate,
                  ),
                ),
              ),
              if (badgeCount != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.amberWarning,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
