import 'package:chongchana/services/api/fetcher.dart';
import 'package:chongchana/services/app_init.dart';
import 'package:chongchana/constants/colors.dart';
import 'package:chongchana/services/article.dart';
import 'package:chongchana/services/checkout.dart';
import 'package:chongchana/services/menu.dart';
import 'package:chongchana/services/inbox.dart';
import 'package:chongchana/services/omise_payment.dart';
import 'package:chongchana/services/wallet.dart';
import 'package:chongchana/services/wallet_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';

import 'package:chongchana/services/auth.dart';
import 'package:chongchana/routing.dart';
import 'package:chongchana/screens/navigator.dart';

class ChongjaroenApp extends StatefulWidget {
  const ChongjaroenApp({Key? key}) : super(key: key);

  @override
  _ChongjaroenAppWidgetState createState() => _ChongjaroenAppWidgetState();
}

class _ChongjaroenAppWidgetState extends State<ChongjaroenApp> {
  final auth = ChongjaroenAuth();
  final appInit = ChongjaroenAppInit();
  final articles = ChongjaroenArticle();
  final menus = ChongjaroenMenus();
  final checkoutService = CheckoutService();
  final inboxService = InboxService();
  final omisePaymentService = OmisePaymentService();
  final walletService = WalletService();
  final walletAuthService = WalletAuthService();
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final RouteState _routeState;
  late final SimpleRouterDelegate _routerDelegate;
  late final TemplateRouteParser _routeParser;

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    /// Configure the parser with all of the app's allowed path templates.
    _routeParser = TemplateRouteParser(
      allowedPaths: [
        "/signin",
        "/home",
        "/menu",
        "/booking",
        "/wallet",
        "/settings",
        "/visit-us",
        "/article/:id",
        "/inbox"
      ],
      // guard: _guard,
      initialRoute: "/home",
    );

    _routeState = RouteState(_routeParser);

    _routerDelegate = SimpleRouterDelegate(
      routeState: _routeState,
      navigatorKey: _navigatorKey,
      builder: (context) => ChongjaroenNavigator(
        navigatorKey: _navigatorKey,
      ),
    );

    // Listen for when the user logs out and display the signin screen.
    auth.addListener(_handleAuthStateChanged);

    // Anti Pattern
    Fetcher.chongjaroenAuth = auth;

    // Defer heavy initialization until after first frame to prevent UI jank
    WidgetsBinding.instance.addPostFrameCallback((_) {
      inboxService.fetchInboxList(true);
      _initOneSignelService();
      if (!auth.alreadyFetchProfile) {
        auth.fetchProfile();
      }
    });

    super.initState();
  }

  void _handleAuthStateChanged() {
    // if (auth.signedIn) {
    articles.fetchArticleList(auth.user.special);
    _handleAppInitStateChanged();

    // Clear wallet data when user logs out
    if (!auth.signedIn) {
      walletService.clearWalletData();

      // Redirect to home if user is on wallet screen
      if (_routeState.route.pathTemplate.startsWith('/wallet')) {
        _routeState.go('/home');
      }
    }
    // }
  }

  void _handleAppInitStateChanged() {
    appInit.fetchDataAppInit();
  }

  @override
  void dispose() {
    auth.removeListener(_handleAuthStateChanged);
    appInit.removeListener(_handleAppInitStateChanged);
    _routeState.dispose();
    _routerDelegate.dispose();
    super.dispose();
  }

  Future<void> _initOneSignelService() async {
    String oneSignelAppId = dotenv.env["ONESIGNAL_APP_ID"] ?? "";

    if (oneSignelAppId.isEmpty) {
      print('[OneSignal] ERROR: ONESIGNAL_APP_ID is empty! Check .env file');
      return;
    }

    print('[OneSignal] Initializing with App ID: $oneSignelAppId');

    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize(oneSignelAppId);

    // Request notification permission
    OneSignal.Notifications.requestPermission(true);

    // Event for handle opened notification
    OneSignal.Notifications.addClickListener((event) {
      Map<String, dynamic>? data = event.notification.additionalData;
      String? type = data?["type"];

      // Route to wallet for financial notifications
      if (type == "wallet_topup" ||
          type == "wallet_topup_failed" ||
          type == "wallet_payment" ||
          type == "wallet_payment_failed" ||
          type == "wallet_transfer_sent" ||
          type == "wallet_transfer_received" ||
          type == "wallet_qr_payment" ||
          type == "wallet_voucher" ||
          type == "wallet_points_convert") {
        _routeState.go('/wallet');
      }
      // Route to inbox for general messages
      else if (data?["sendingMethod"] == "inbox_push" ||
               data?["sendingMethod"] == "push") {
        _routeState.go('/inbox');
      }
      // Default to home
      else {
        _routeState.go('/home');
      }
    });

    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      // Store notification in inbox for all wallet events
      inboxService.setNewItemFromNotification(event.notification);

      // Trigger wallet notification callback if it's a wallet event
      Map<String, dynamic>? data = event.notification.additionalData;
      String? type = data?["type"];

      // Handle wallet QR payments with callback (when actively waiting)
      if (type == "wallet_qr_payment" && inboxService.onWalletNotification != null) {
        event.preventDefault(); // Prevent default notification for QR (handled by callback)
        inboxService.onWalletNotification!(data ?? {});
      } else if (type == "wallet_topup" ||
                 type == "wallet_topup_failed" ||
                 type == "wallet_payment" ||
                 type == "wallet_payment_failed" ||
                 type == "wallet_transfer_sent" ||
                 type == "wallet_transfer_received") {
        // For other wallet notifications (credit card, transfers, etc),
        // let them display normally even in foreground
        // DON'T call event.preventDefault() - let the notification show
      } else {
        // For non-wallet events, prevent default display
        event.preventDefault();
      }
    });
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider<ChongjaroenAuth>(create: (_) => auth),
          ChangeNotifierProvider<ChongjaroenAppInit>(create: (_) => appInit),
          ChangeNotifierProvider<ChongjaroenArticle>(create: (_) => articles),
          ChangeNotifierProvider<ChongjaroenMenus>(create: (_) => menus),
          ChangeNotifierProvider<CheckoutService>(
              create: (_) => checkoutService),
          ChangeNotifierProvider<InboxService>(create: (_) => inboxService),
          ChangeNotifierProvider<OmisePaymentService>(
              create: (_) => omisePaymentService),
          ChangeNotifierProvider<WalletService>(create: (_) => walletService),
          ChangeNotifierProvider<WalletAuthService>(create: (_) => walletAuthService),
        ],
        child: RouteStateScope(
          notifier: _routeState,
          child: ChongjaroenAuthScope(
            notifier: auth,
            child: MaterialApp.router(
              routerDelegate: _routerDelegate,
              routeInformationParser: _routeParser,
              theme: ThemeData(
                colorScheme: ThemeData.light().colorScheme.copyWith(
                      surface: ChongjaroenColors.blackColor,
                    ),
                fontFamily: "FC Iconic",
                textTheme: const TextTheme(
                  displayLarge: TextStyle(
                    fontSize: 30.0,
                    color: ChongjaroenColors.blackColor,
                    fontWeight: FontWeight.w600,
                  ),
                  displayMedium: TextStyle(
                    fontSize: 28.0,
                    color: ChongjaroenColors.blackColor,
                    fontWeight: FontWeight.w600,
                  ),
                  displaySmall: TextStyle(
                    fontSize: 26.0,
                    color: ChongjaroenColors.blackColor,
                    fontWeight: FontWeight.w600,
                  ),
                  headlineMedium: TextStyle(
                    fontSize: 24.0,
                    color: ChongjaroenColors.blackColor,
                    fontWeight: FontWeight.w600,
                  ),
                  headlineSmall: TextStyle(
                    fontSize: 22.0,
                    color: ChongjaroenColors.blackColor,
                    fontWeight: FontWeight.w600,
                  ),
                  titleLarge: TextStyle(
                    fontSize: 20.0,
                    color: ChongjaroenColors.blackColor,
                    fontWeight: FontWeight.w600,
                  ),
                  titleMedium: TextStyle(
                    fontSize: 18.0,
                    color: ChongjaroenColors.blackColor,
                    fontWeight: FontWeight.w600,
                  ),
                  titleSmall: TextStyle(
                    fontSize: 16.0,
                    color: ChongjaroenColors.blackColor,
                    fontWeight: FontWeight.w600,
                  ),
                  bodyLarge: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w400,
                    color: ChongjaroenColors.darkGrayColors,
                  ),
                  bodyMedium: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w400,
                    color: ChongjaroenColors.darkGrayColors,
                    height: 1.5,
                  ),
                ),
                secondaryHeaderColor: ChongjaroenColors.secondaryColors,
                primarySwatch: ChongjaroenColors.primaryColors,
                pageTransitionsTheme: const PageTransitionsTheme(
                  builders: <TargetPlatform, PageTransitionsBuilder>{
                    TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                    TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
                    TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
                    TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
                  },
                ),
              ),
            ),
          ),
        ),
      );
}
