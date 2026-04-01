import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chongchana/services/wallet_auth.dart';
import 'package:chongchana/screens/wallet/wallet_security.dart';
import 'package:chongchana/constants/colors.dart';

void main() {
  runApp(const WalletSecurityTestApp());
}

class WalletSecurityTestApp extends StatelessWidget {
  const WalletSecurityTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<WalletAuthService>(
          create: (_) => WalletAuthService(),
        ),
      ],
      child: MaterialApp(
        title: 'Wallet Security Test',
        theme: ThemeData(
          primarySwatch: ChongjaroenColors.primaryColors,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const WalletSecurityScreen(),
      ),
    );
  }
}