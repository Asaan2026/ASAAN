import 'package:flutter/material.dart';
import 'package:vortex_app/presentation/screens/auth/forgot_password_screen.dart';
import 'package:vortex_app/presentation/screens/auth/login_screen.dart';
import 'package:vortex_app/presentation/screens/auth/register_screen.dart';
import 'package:vortex_app/presentation/screens/auth/reset_password_screen.dart';
import 'package:vortex_app/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:vortex_app/presentation/screens/splash/splash_screen.dart';
import 'package:vortex_app/presentation/screens/products/product_detail_screen.dart';
import 'package:vortex_app/presentation/screens/categories/categories_screen.dart';
import 'package:vortex_app/presentation/screens/categories/category_products_screen.dart';
import 'package:vortex_app/presentation/screens/main/main_navigation_screen.dart';
// import 'package:vortex_app/presentation/screens/checkout/shipping_screen.dart'; // Requires parameters
import 'package:vortex_app/presentation/screens/checkout/order_success_screen.dart';
import 'package:vortex_app/presentation/screens/order/order_detail_screen.dart';
import 'package:vortex_app/presentation/screens/order/order_list_screen.dart';
import 'package:vortex_app/presentation/screens/profile/edit_profile_screen.dart';
import 'package:vortex_app/presentation/screens/profile/address_management_screen.dart';
import 'package:vortex_app/presentation/screens/profile/identity_verification_screen.dart';
import 'package:vortex_app/presentation/screens/profile/referrals_screen.dart';
import 'package:vortex_app/presentation/screens/profile/language_screen.dart';
import 'package:vortex_app/presentation/screens/notifications/notifications_screen.dart';
import 'package:vortex_app/presentation/screens/services/services_screen.dart';
import 'package:vortex_app/presentation/screens/services/service_detail_screen.dart';
import 'package:vortex_app/presentation/screens/services/service_booking_screen.dart';
import 'package:vortex_app/presentation/screens/support/help_support_screen.dart';
import 'package:vortex_app/presentation/screens/support/about_us_screen.dart';
import 'package:vortex_app/presentation/screens/support/terms_conditions_screen.dart';
import 'package:vortex_app/presentation/screens/support/privacy_policy_screen.dart';
import 'package:vortex_app/presentation/screens/search/search_screen.dart';

/// App router configuration
class AppRouter {
  AppRouter._();

  /// The app's single navigator. A notification tap (in-app or push) happens
  /// outside any widget, so it has no BuildContext; this key lets it change
  /// screens from there.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// The route currently on top of the root navigator. A notification tap uses
  /// this to avoid pushing a screen the customer is already looking at, which
  /// would appear as a refresh with nothing changing.
  static String? currentRoute;

  /// Keeps [currentRoute] honest when screens are popped, not just pushed. A
  /// push alone would leave a popped screen marked as "on top" forever.
  static final NavigatorObserver routeObserver = _RouteTracker();

  // Route names
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String home = '/home';

  /// Index of the basket in the shop's bottom bar, passed to the home route as
  /// {'tab': AppRouter.cartTab} to land there (see MainNavigationScreen).
  static const int cartTab = 2;
  static const String productDetail = '/product-detail';
  static const String categories = '/categories';
  static const String categoryProducts = '/category-products';
  static const String shipping = '/shipping';
  static const String payment = '/payment';
  static const String review = '/review';
  static const String orderSuccess = '/order-success';
  static const String orderDetail = '/order-detail';
  static const String orderList = '/order-list';
  static const String editProfile = '/edit-profile';
  static const String addressManagement = '/address-management';
  static const String identityVerification = '/identity-verification';
  static const String referrals = '/referrals';
  static const String language = '/language';
  static const String notifications = '/notifications';
  static const String services = '/services';
  static const String serviceDetail = '/service-detail';
  static const String serviceBooking = '/service-booking';
  static const String helpSupport = '/help-support';
  static const String aboutUs = '/about-us';
  static const String termsConditions = '/terms-conditions';
  static const String privacyPolicy = '/privacy-policy';
  static const String search = '/search';

  /// Generate routes
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Remember the top screen so a notification tap can tell whether it would
    // just re-open the screen already on display.
    currentRoute = settings.name;
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );

      case onboarding:
        return MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
          settings: settings,
        );

      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );

      case register:
        return MaterialPageRoute(
          builder: (_) => const RegisterScreen(),
          settings: settings,
        );

      case forgotPassword:
        return MaterialPageRoute(
          builder: (_) => const ForgotPasswordScreen(),
          settings: settings,
        );

      case resetPassword:
        return MaterialPageRoute(
          builder: (_) => const ResetPasswordScreen(),
          settings: settings,
        );

      case home:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => MainNavigationScreen(
            initialTab: (args?['tab'] as num?)?.toInt() ?? 0,
          ),
          settings: settings,
        );

      case productDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ProductDetailScreen(
            product: args?['product'] ?? {},
          ),
          settings: settings,
        );

      case categories:
        return MaterialPageRoute(
          builder: (_) => const CategoriesScreen(),
          settings: settings,
        );

      case categoryProducts:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => CategoryProductsScreen(
            categoryId: args?['categoryId'] ?? 1,
            categoryName: args?['categoryName'] ?? 'Products',
          ),
          settings: settings,
        );

      // Shipping screen now requires parameters - navigate with data from CheckoutScreen
      // case shipping:
      //   return MaterialPageRoute(
      //     builder: (_) => const ShippingScreen(selectedAddress: {}),
      //     settings: settings,
      //   );

      // Payment screen now requires parameters - navigate with data from ShippingScreen
      // case payment:
      //   return MaterialPageRoute(
      //     builder: (_) => const PaymentScreen(),
      //     settings: settings,
      //   );

      // Review screen now requires parameters - navigate from PaymentScreen with checkout summary
      // case review:
      //   return MaterialPageRoute(
      //     builder: (_) => const ReviewScreen(),
      //     settings: settings,
      //   );

      case orderSuccess:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(
            orderId: (args?['orderId'] as num?)?.toInt(),
            orderNumber: args?['orderNumber'] ?? '',
            totalAmount: (args?['totalAmount'] as num?)?.toDouble() ?? 0.0,
          ),
          settings: settings,
        );

      case orderDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => OrderDetailScreen(
            // The id is what lets the screen fetch the real order; without it
            // there is nothing to show but the few facts passed in here.
            orderId: (args?['orderId'] as num?)?.toInt(),
            orderNumber: args?['orderNumber'] ?? '',
            orderDate: args?['orderDate'] ?? '',
            orderStatus: args?['orderStatus'] ?? '',
            totalAmount: (args?['totalAmount'] as num?)?.toDouble() ?? 0.0,
          ),
          settings: settings,
        );

      case orderList:
        return MaterialPageRoute(
          builder: (_) => const OrderListScreen(),
          settings: settings,
        );

      case editProfile:
        return MaterialPageRoute(
          builder: (_) => const EditProfileScreen(),
          settings: settings,
        );

      case addressManagement:
        return MaterialPageRoute(
          builder: (_) => const AddressManagementScreen(),
          settings: settings,
        );

      case identityVerification:
        return MaterialPageRoute(
          builder: (_) => const IdentityVerificationScreen(),
          settings: settings,
        );

      case referrals:
        return MaterialPageRoute(
          builder: (_) => const ReferralsScreen(),
          settings: settings,
        );

      case language:
        return MaterialPageRoute(
          builder: (_) => const LanguageScreen(),
          settings: settings,
        );

      case notifications:
        return MaterialPageRoute(
          builder: (_) => const NotificationsScreen(),
          settings: settings,
        );

      case services:
        return MaterialPageRoute(
          builder: (_) => const ServicesScreen(),
          settings: settings,
        );

      case serviceDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ServiceDetailScreen(slug: args?['slug'] ?? ''),
          settings: settings,
        );

      case serviceBooking:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ServiceBookingScreen(
            slug: args?['slug'] ?? '',
            serviceName: args?['serviceName'] ?? 'Service',
          ),
          settings: settings,
        );

      case helpSupport:
        return MaterialPageRoute(
          builder: (_) => const HelpSupportScreen(),
          settings: settings,
        );

      case aboutUs:
        return MaterialPageRoute(
          builder: (_) => const AboutUsScreen(),
          settings: settings,
        );

      case termsConditions:
        return MaterialPageRoute(
          builder: (_) => const TermsConditionsScreen(),
          settings: settings,
        );

      case privacyPolicy:
        return MaterialPageRoute(
          builder: (_) => const PrivacyPolicyScreen(),
          settings: settings,
        );

      case search:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => SearchScreen(
            initialQuery: args?['query'] as String?,
          ),
          settings: settings,
        );

      // TODO: Add more routes as we implement more screens

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }

  /// Page transitions
  static Route<dynamic> fadeTransition(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static Route<dynamic> slideTransition(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

/// Follows the root navigator so a notification tap knows which screen is on
/// top even after screens are popped.
class _RouteTracker extends NavigatorObserver {
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppRouter.currentRoute = previousRoute?.settings.name;
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppRouter.currentRoute = previousRoute?.settings.name;
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    AppRouter.currentRoute = newRoute?.settings.name;
  }
}
