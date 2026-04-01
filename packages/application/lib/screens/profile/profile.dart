import 'package:chongchana/constants/colors.dart';
import 'package:chongchana/constants/locales.dart';
import 'package:chongchana/models/user.dart';
import 'package:chongchana/screens/profile/delete_account.dart';
import 'package:chongchana/screens/profile/profile_image.dart';
import 'package:chongchana/screens/wallet/wallet_security.dart';
import 'package:chongchana/widgets/application_version.dart';
import 'package:chongchana/widgets/page_title.dart';
import 'package:chongchana/widgets/singin_description.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chongchana/services/auth.dart';
import 'dart:math' as math;

// Constants for responsive design
class _ProfileConstants {
  static const double topologyCircleSize = 200.0;
  static const double topologyCircleSizeSmall = 160.0;
  static const double profileImageBorderWidth = 3.0;
  static const double cardBorderRadius = 16.0;
  static const double badgeBorderRadius = 12.0;
  static const double iconSize = 18.0;

  // Responsive spacing
  static double getHeaderHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return screenHeight * 0.35; // 35% of screen height
  }

  static EdgeInsets getContentPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return EdgeInsets.symmetric(horizontal: width * 0.04);
  }
}

class ProfileWidgets extends StatefulWidget {
  const ProfileWidgets({Key? key}) : super(key: key);

  @override
  _ProfileWidgetsState createState() => _ProfileWidgetsState();
}

class _ProfileWidgetsState extends State<ProfileWidgets> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ChongjaroenAuth>(
      builder: (context, auth, _) => _ProfileView(user: auth.user),
    );
  }
}

class _ProfileView extends StatelessWidget {
  final User user;

  const _ProfileView({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            _buildProfileHeader(context),
            _buildContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Stack(
        children: [
          // Background topology shapes
          ..._buildTopologyBackground(),

          // Profile content
          Container(
            width: double.infinity,
            color: ChongjaroenColors.primaryColors,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 24,
              left: 16,
              right: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Profile image with ring
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ChongjaroenColors.secondaryColors,
                      width: _ProfileConstants.profileImageBorderWidth,
                    ),
                  ),
                  child: ProfileImage(user: user),
                ),
                const SizedBox(height: 12),

                // Name
                Text(
                  "${user.firstName} ${user.lastName}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),

                // User ID
                Text(
                  "ID #${user.userId}",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),

                // Badges - Partner & Points
                _buildBadges(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTopologyBackground() {
    return [
      Positioned(
        top: -100,
        right: -50,
        child: Transform.rotate(
          angle: math.pi / 6,
          child: Container(
            width: _ProfileConstants.topologyCircleSize,
            height: _ProfileConstants.topologyCircleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ChongjaroenColors.primaryColors.withOpacity(0.1),
            ),
          ),
        ),
      ),
      Positioned(
        top: 100,
        left: -80,
        child: Container(
          width: _ProfileConstants.topologyCircleSizeSmall,
          height: _ProfileConstants.topologyCircleSizeSmall,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ChongjaroenColors.secondaryColors.withOpacity(0.08),
          ),
        ),
      ),
    ];
  }

  Widget _buildBadges(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        if (user.special) _buildPartnerBadge(),
        _buildPointsBadge(),
      ],
    );
  }

  Widget _buildPartnerBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: ChongjaroenColors.secondaryColors,
        borderRadius: BorderRadius.circular(_ProfileConstants.badgeBorderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            Locales.Partner,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(_ProfileConstants.badgeBorderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            "${user.points} pts",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _buildInfoCard(context),
          const SizedBox(height: 16),
          _buildSignOutButton(context),
          const SizedBox(height: 12),
          const SigninDescriptionWidget(),
          const DeleteAccountWidgets(),
          const SizedBox(height: 12),
          const ApplicationVersion(),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ]),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_ProfileConstants.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _InfoTile(
            icon: Icons.phone,
            label: Locales.MobileNumber,
            value: user.phone,
            isFirst: true,
          ),
          _InfoTile(
            icon: Icons.email,
            label: Locales.Email,
            value: user.email,
          ),
          _InfoTile(
            icon: Icons.security,
            label: 'Wallet Security',
            value: 'Manage protection',
            onTap: () => _navigateToWalletSecurity(context),
            showArrow: true,
            isLast: true,
          ),
        ],
      ),
    );
  }

  void _navigateToWalletSecurity(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const WalletSecurityScreen(),
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return OutlinedButton(
      onPressed: () => _handleSignOut(context),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(
          color: ChongjaroenColors.redColors,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_ProfileConstants.badgeBorderRadius),
        ),
      ),
      child: Text(
        'Sign Out',
        style: TextStyle(
          color: ChongjaroenColors.redColors,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _handleSignOut(BuildContext context) {
    final authState = ChongjaroenAuthScope.of(context);
    authState.signOut();
  }
}

// Extracted InfoTile widget following DRY principle
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool showArrow;
  final bool isFirst;
  final bool isLast;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.showArrow = false,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(_ProfileConstants.cardBorderRadius) : Radius.zero,
        bottom: isLast ? const Radius.circular(_ProfileConstants.cardBorderRadius) : Radius.zero,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
        ),
        child: Row(
          children: [
            _buildIcon(),
            const SizedBox(width: 12),
            Expanded(child: _buildLabelValue()),
            if (showArrow) _buildArrow(),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: ChongjaroenColors.primaryColors.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: ChongjaroenColors.primaryColors,
        size: _ProfileConstants.iconSize,
      ),
    );
  }

  Widget _buildLabelValue() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildArrow() {
    return Icon(
      Icons.chevron_right,
      color: Colors.grey[400],
      size: 20,
    );
  }
}
