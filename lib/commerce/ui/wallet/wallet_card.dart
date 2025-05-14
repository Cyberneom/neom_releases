import 'dart:math';

import 'package:flutter/cupertino.dart'; // For CupertinoIcons if used, e.g. chip
import 'package:flutter/material.dart';
import 'package:neom_commons/neom_commons.dart'; // Assuming this imports AppTheme, AppColor, AppAssets, AppTranslationConstants, etc.
// If not, you might need individual imports:
// import 'package:neom_commons/core/utils/app_theme.dart';
// import 'package:neom_commons/core/utils/app_color.dart';
// import 'package:neom_commons/core/utils/constants/app_assets.dart';
// import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
// import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';


import 'wallet_controller.dart'; // Your WalletController
import 'package:get/get.dart'; // For GetBuilder

class WalletCard extends StatelessWidget {
  const WalletCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WalletController>(
      id: AppPageIdConstants.walletHistory, // Ensure this ID matches if you update from controller
      // init: WalletController(), // init is usually not needed here if controller is already initialized by the page
      builder: (_) => Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.width / 1.8, // Slightly taller for more content space
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(20.0)), // Slightly less rounded
          gradient: LinearGradient(
            colors: [
              AppColor.getMain().withOpacity(0.95), // Slightly more opaque main color
              AppColor.main75, // Your existing secondary gradient color
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            transform: const GradientRotation(pi / 5), // Adjusted rotation slightly
          ),
          boxShadow: [
            BoxShadow(
              color: AppColor.getMain().withOpacity(0.3), // Shadow based on main color
              blurRadius: 15, // Softer blur
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1), // A darker, more subtle shadow
              blurRadius: 25,
              offset: const Offset(0, 12),
            ),
          ],
          border: Border.all( // Adding a subtle border
            color: Colors.white.withOpacity(0.15),
            width: 0.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribute space
            children: [
              // Top Row: Coin Name and Chip Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppTranslationConstants.appCoin.tr.toUpperCase(),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5, // Increased letter spacing
                    ),
                  ),
                  Icon(
                    Icons.memory, // Material chip icon
                    color: Colors.white.withOpacity(0.7),
                    size: 30,
                  ),
                ],
              ),

              // Middle: Icon and Balance (centered within its available space)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: AppTheme.fullWidth(context) / 7.5, // Adjusted icon size
                      height: AppTheme.fullWidth(context) / 7.5,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.all(Radius.circular(12.0)),
                        child: Image.asset(AppAssets.appCoin, fit: BoxFit.contain),
                      ),
                    ),
                    AppTheme.heightSpace20, // Increased space
                    Text(
                      // Ensure _.wallet.amount is available and is a number
                      _.wallet.amount.truncate().toString().replaceAllMapped(
                          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},'),
                      style: const TextStyle(
                        fontSize: 44, // Prominent balance
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Row: Dummy Card Number
              Text(
                "**** **** **** ${_.wallet.id.isNotEmpty ? _.wallet.id.substring(_.wallet.id.length - min(4,_.wallet.id.length)) : '****'}", // Display last 4 digits of wallet ID or a placeholder
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withOpacity(0.75),
                  letterSpacing: 2.5, // Wider spacing for card number feel
                  fontFamily: 'monospace', // Monospace font for card numbers
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
