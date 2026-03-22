import 'package:chongchana/constants/colors.dart';
import 'package:chongchana/constants/locales.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:chongchana/constants/chongjaroen_icons.dart';
import 'package:chongchana/routing.dart';
import 'package:chongchana/services/auth.dart';
import 'package:flutter/services.dart';
import 'scaffold_body.dart';

class ChongjaroenScaffold extends StatefulWidget {
  const ChongjaroenScaffold({
    Key? key,
  }) : super(key: key);

  @override
  _ChongjaroenScaffoldState createState() => _ChongjaroenScaffoldState();
}

class _ChongjaroenScaffoldState extends State<ChongjaroenScaffold> {
  
  @override
  Widget build(BuildContext context) {
    final routeState = RouteStateScope.of(context);

    return Consumer<ChongjaroenAuth>(
      builder: (context, auth, _) {
        final bool isSignedIn = auth.signedIn;
        int selectedIndex = _getSelectedIndex(routeState.route.pathTemplate, isSignedIn);

        void _destinationTapped(int index) {
          if (index == 0) {
            routeState.go('/home');
          } else if (index == 1) {
            routeState.go('/booking');
          } else if (index == 2) {
            routeState.go('/menu');
          } else if (index == 3 && isSignedIn) {
            routeState.go('/wallet');
          }
        }

        // Build navigation items dynamically based on authentication state
        List<BottomNavigationBarItem> navItems = [
          const BottomNavigationBarItem(
            icon: Icon(ChongjaroenIcons.home),
            label: Locales.Home,
          ),
          const BottomNavigationBarItem(
            icon: Icon(ChongjaroenIcons.calendar),
            label: Locales.TabBooking,
          ),
          const BottomNavigationBarItem(
            icon: Icon(ChongjaroenIcons.book),
            label: Locales.Menu,
          ),
        ];

        // Only add wallet tab if user is signed in
        if (isSignedIn) {
          navItems.add(
            const BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet),
              label: Locales.Wallet,
            ),
          );
        }

        return Scaffold(
          body: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light
                .copyWith(statusBarColor: Theme.of(context).primaryColor),
            child: const SafeArea(
              top: false,
              child: ChongjaroenScaffoldBody(),
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: navItems,
            currentIndex: selectedIndex,
            iconSize: 26,
            backgroundColor: Colors.white,
            unselectedItemColor: Colors.grey.shade700,
            selectedItemColor: ChongjaroenColors.secondaryColors,
            selectedFontSize: 13,
            unselectedFontSize: 12,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
            type: BottomNavigationBarType.fixed,
            elevation: 8,
            onTap: _destinationTapped,
          ),
        );
      },
    );
  }

  int _getSelectedIndex(String pathTemplate, bool isSignedIn) {
    if (pathTemplate == '/booking') {
      return 1;
    } else if (pathTemplate == '/menu') {
      return 2;
    } else if (pathTemplate.startsWith('/wallet') && isSignedIn) {
      return 3;
    } else {
      return 0;
    }
  }
}
