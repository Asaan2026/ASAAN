import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vortex_app/core/constants/app_colors.dart';
import 'package:vortex_app/presentation/screens/home/home_screen.dart';
import 'package:vortex_app/presentation/screens/categories/categories_screen.dart';
import 'package:vortex_app/presentation/screens/categories/category_products_screen.dart';
import 'package:vortex_app/presentation/screens/cart/cart_screen.dart';
import 'package:vortex_app/presentation/screens/wishlist/wishlist_screen.dart';
import 'package:vortex_app/presentation/screens/profile/profile_screen.dart';
import 'package:vortex_app/presentation/screens/products/new_arrivals_screen.dart';
import 'package:vortex_app/presentation/screens/products/flash_sales_screen.dart';
import 'package:vortex_app/presentation/screens/products/featured_products_screen.dart';
import 'package:vortex_app/presentation/screens/products/product_detail_screen.dart';
import 'package:vortex_app/data/services/cart_service.dart';
import 'package:vortex_app/l10n/app_localizations.dart';

class MainNavigationScreen extends StatefulWidget {
  /// Which tab to open on. Used to come back from a pushed screen straight
  /// into the basket, for instance after reordering a past order.
  final int initialTab;

  const MainNavigationScreen({super.key, this.initialTab = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  int _cartCount = 0;
  final CartService _cartService = CartService();
  int _cartRefreshKey = 0; // Used to force cart screen rebuild
  int _wishlistRefreshKey = 0; // Used to force wishlist screen rebuild

  // Each scrollable tab keeps its own history. Holding the keys lets the phone's
  // back button step back through the tab you are in before it leaves the tab.
  final GlobalKey<NavigatorState> _homeNavKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _categoriesNavKey =
      GlobalKey<NavigatorState>();

  // The tab we were on before this one, so back can return there.
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedIndex = widget.initialTab;
    _previousIndex = widget.initialTab;
    _loadCartCount();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reload cart count and refresh cart when app resumes
      _loadCartCount();
      _refreshCart();
    }
  }

  void _refreshCart() {
    // Force cart screen to rebuild by changing its key
    setState(() {
      _cartRefreshKey++;
    });
  }

  /// The navigator for the tab currently on screen, if it has one. Only Home
  /// and Categories are stacked; the other tabs are single screens.
  NavigatorState? _currentTabNavigator() {
    switch (_selectedIndex) {
      case 0:
        return _homeNavKey.currentState;
      case 1:
        return _categoriesNavKey.currentState;
      default:
        return null;
    }
  }

  /// Handle the phone's back button.
  ///
  /// First step back inside the current tab. When the tab is already at its
  /// first screen, return to the tab we came from. Only when there is nowhere
  /// left to go do we ask before closing the app.
  Future<bool> _onWillPop() async {
    final tabNavigator = _currentTabNavigator();
    if (tabNavigator != null && tabNavigator.canPop()) {
      tabNavigator.pop();
      return false;
    }

    // Not the first tab: step back to the tab we came from.
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = _previousIndex;
      });
      return false;
    }

    final shouldExit = await _confirmExit();
    return shouldExit;
  }

  Future<bool> _confirmExit() async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.exitAppTitle),
        content: Text(l10n.exitAppMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.exitAppConfirm),
          ),
        ],
      ),
    );
    // A dialog dismissed without a choice (tap outside, hardware back) means
    // stay, never exit.
    return result ?? false;
  }

  void _onTabTapped(int index) {
    if (index != _selectedIndex) {
      _previousIndex = _selectedIndex;
    }
    setState(() {
      _selectedIndex = index;
    });

    // Reload cart when cart tab is selected
    if (index == 2) {
      _refreshCart();
      _loadCartCount();
    }

    // Reload wishlist when wishlist tab is selected
    if (index == 3) {
      setState(() {
        _wishlistRefreshKey++;
      });
    }
  }

  Future<void> _loadCartCount() async {
    try {
      final count = await _cartService.getCartCount();
      if (mounted) {
        setState(() {
          _cartCount = count;
        });
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _onWillPop();
        if (shouldExit && mounted) {
          // Nothing is left to go back to and the customer confirmed, so close
          // the app the normal way.
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            Navigator(
              key: _homeNavKey,
              initialRoute: '/',
              onGenerateRoute: (settings) {
                if (settings.name == '/new-arrivals') {
                  return MaterialPageRoute(
                    builder: (context) => NewArrivalsScreen(
                      onCartChanged: _loadCartCount,
                    ),
                  );
                }
                if (settings.name == '/flash-sales') {
                  return MaterialPageRoute(
                    builder: (context) => FlashSalesScreen(
                      onCartChanged: _loadCartCount,
                    ),
                  );
                }
                if (settings.name == '/featured-products') {
                  return MaterialPageRoute(
                    builder: (context) => FeaturedProductsScreen(
                      onCartChanged: _loadCartCount,
                    ),
                  );
                }
                // Product detail opened from a Home card is pushed here too, so
                // backing out of a product returns to the Home tab.
                if (settings.name == '/product-detail') {
                  final args = settings.arguments as Map<String, dynamic>?;
                  return MaterialPageRoute(
                    builder: (context) => ProductDetailScreen(
                      product:
                          (args?['product'] as Map<String, dynamic>?) ?? {},
                    ),
                  );
                }
                // Default route for Home (/ or null)
                return MaterialPageRoute(
                  builder: (context) =>
                      HomeScreen(onCartChanged: _loadCartCount),
                );
              },
            ),
            Navigator(
              key: _categoriesNavKey,
              onGenerateRoute: (settings) {
                if (settings.name == '/category-products') {
                  final args = settings.arguments as Map<String, dynamic>?;
                  return MaterialPageRoute(
                    builder: (context) => CategoryProductsScreen(
                      categoryId: args?['categoryId'] ?? 1,
                      categoryName: args?['categoryName'] ?? 'Products',
                    ),
                  );
                }
                // Product detail is opened on THIS tab's navigator, not the root
                // one. The category list lives here, so the detail has to be
                // pushed here too -- otherwise the two stacks get out of step and
                // backing out of a product lands on the wrong screen.
                if (settings.name == '/product-detail') {
                  final args = settings.arguments as Map<String, dynamic>?;
                  return MaterialPageRoute(
                    builder: (context) => ProductDetailScreen(
                      product:
                          (args?['product'] as Map<String, dynamic>?) ?? {},
                    ),
                  );
                }
                return MaterialPageRoute(
                  builder: (context) => const CategoriesScreen(),
                );
              },
            ),
            CartScreen(
              key: ValueKey('cart_$_cartRefreshKey'),
              onCartChanged: _loadCartCount,
              onContinueShopping: () {
                setState(() {
                  _selectedIndex = 0;
                });
              },
            ),
            WishlistScreen(key: ValueKey('wishlist_$_wishlistRefreshKey')),
            const ProfileScreen(),
          ],
        ),
        bottomNavigationBar: _buildBottomNavBar(isDark),
      ),
    );
  }

  Widget _buildBottomNavBar(bool isDark) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2633) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(Icons.home, l10n.navHome, 0, isDark),
              _buildNavItem(
                  Icons.category_outlined, l10n.navCategories, 1, isDark),
              _buildNavItemWithBadge(Icons.shopping_cart_outlined, l10n.navCart,
                  2, isDark, _cartCount > 0 ? '$_cartCount' : null),
              _buildNavItem(
                  Icons.favorite_outline, l10n.navWishlist, 3, isDark),
              _buildNavItem(Icons.person_outline, l10n.navProfile, 4, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItemWithBadge(
    IconData icon,
    String label,
    int index,
    bool isDark,
    String? badgeCount,
  ) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        _onTabTapped(index);
        _loadCartCount();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade400),
              ),
              if (badgeCount != null)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      badgeCount,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, bool isDark) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        _onTabTapped(index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: isSelected
                ? AppColors.primary
                : (isDark ? Colors.grey.shade400 : Colors.grey.shade400),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade400),
            ),
          ),
        ],
      ),
    );
  }
}
