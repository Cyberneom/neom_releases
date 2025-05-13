import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:neom_commons/neom_commons.dart';

import 'wallet_controller.dart';
import 'package:get/get.dart';

class WalletCard extends StatelessWidget {
  const WalletCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WalletController>(
        id: AppPageIdConstants.walletHistory,
        init: WalletController(),
    builder: (_) => Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.width / 2,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            blurRadius: 45,
            color: Colors.grey.shade400,
            offset: const Offset(0, 30),
          )
        ],
        borderRadius: const BorderRadius.all(Radius.circular(25.0)),
        // border: Border.all(
        //   color: AppColor.yellow,
        //   width: 1,
        // ),
        gradient: LinearGradient(
          colors: [
            AppColor.getMain(),
            AppColor.main75,
          ],
          transform: const GradientRotation(pi / 4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppTranslationConstants.appCoin.tr.toUpperCase(),
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            AppTheme.heightSpace10,
            SizedBox(
                width: AppTheme.fullWidth(context)/10,
                height: AppTheme.fullWidth(context)/10,
                child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                    child: Image.asset(AppAssets.appCoin)
                )
            ),
            AppTheme.heightSpace10,
            Text(
              _.wallet.amount.truncate().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},'),
              style: TextStyle(
                fontSize: 35,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            // const Spacer(),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: [
            //     Row(
            //       children: [
            //         Container(
            //           width: 30,
            //           height: 30,
            //           decoration: const BoxDecoration(
            //             color: Colors.white30,
            //             shape: BoxShape.circle,
            //           ),
            //           child: const Center(
            //             child: Icon(
            //               CupertinoIcons.arrow_down,
            //               color: Colors.green,
            //             ),
            //           ),
            //         ),
            //         const SizedBox(width: 12),
            //         Column(
            //           crossAxisAlignment: CrossAxisAlignment.start,
            //           children: [
            //             Text(
            //               'Ingreso',
            //               style: TextStyle(
            //                 fontSize: 14,
            //                 color: Colors.grey[300],
            //               ),
            //             ),
            //             const Text(
            //               '2300.00',
            //               style: TextStyle(
            //                 fontSize: 18,
            //                 fontWeight: FontWeight.w500,
            //                 color: Colors.white,
            //               ),
            //             ),
            //           ],
            //         ),
            //       ],
            //     ),
            //     Row(
            //       children: [
            //         Container(
            //           width: 30,
            //           height: 30,
            //           decoration: const BoxDecoration(
            //             color: Colors.white30,
            //             shape: BoxShape.circle,
            //           ),
            //           child: const Center(
            //             child: Icon(
            //               CupertinoIcons.arrow_up,
            //               color: Colors.red,
            //             ),
            //           ),
            //         ),
            //         const SizedBox(width: 12),
            //         Column(
            //           crossAxisAlignment: CrossAxisAlignment.start,
            //           children: [
            //             Text(
            //               'Gasto',
            //               style: TextStyle(
            //                 fontSize: 14,
            //                 color: Colors.grey[300],
            //               ),
            //             ),
            //             const Text(
            //               '800.00',
            //               style: TextStyle(
            //                 fontSize: 18,
            //                 fontWeight: FontWeight.w500,
            //                 color: Colors.white,
            //               ),
            //             ),
            //           ],
            //         ),
            //       ],
            //     ),
            //   ],
            // )
          ],
        ),
      ),),
    );
  }
}
