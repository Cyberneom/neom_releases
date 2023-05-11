// import 'package:emxi/core/ui/drawer/settings/widgets/headerWidget.dart';
// import 'package:emxi/core/ui/drawer/settings/widgets/settingsRowWidget.dart';
// import 'package:emxi/core/ui/widgets/gig-appbar-child.dart';
// import 'package:emxi/core/utils/gig-app-theme.dart';
// import 'package:emxi/core/utils/constants/gig_route_constants.dart';
// import 'package:flutter/material.dart';
// import 'package:emxi/core/utils/constants/gig_translation_constants.dart';
// import 'package:emxi/core/utils/gig-utilities.dart';
// import 'package:get/get.dart';
//
// //TODO
// class PrivacyAndSafetyPage extends StatelessWidget {
//   const PrivacyAndSafetyPage({Key? key}) : super(key: key);
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: GigAppBarChild('Privacy and safety'),
//       body: Container(
//         decoration: GigAppTheme.gigBoxDecoration,
//         child: ListView(
//         physics: const BouncingScrollPhysics(),
//         children: <Widget>[
//           const HeaderWidget('Posts'),
//           SettingRowWidget(
//             "Protect what you share",
//             subtitle:
//                 'Only current followers and people you approve in future will be able to see your posts, itemlists, gig events, etc.',
//             vPadding: 15,
//             showDivider: false,
//             visibleSwitch: true,
//           ),
//           const HeaderWidget(
//             'Inbox Message',
//             secondHeader: true,
//           ),
//           SettingRowWidget(
//             'Inbox Message',
//              navigateTo: GigRouteConstants.SETTINGS_DIRECT_MESSAGE,
//           ),
//           const HeaderWidget(
//             'Discoverability and contacts',
//             secondHeader: true,
//           ),
//           SettingRowWidget(
//             "Discoverability and contacts",
//             showDivider: false,
//           ),
//           SettingRowWidget(
//             "",
//             subtitle:
//                 'Learn more about how this data is used to connect you with people',
//             vPadding: 15,
//             showDivider: false,
//           ),
//           const HeaderWidget(
//             'Safety',
//             secondHeader: true,
//           ),
//           const HeaderWidget(
//             'Location',
//             secondHeader: true,
//           ),
//           SettingRowWidget(
//             "Precise location",
//             subtitle:
//                 'Disabled \n\n\nIf enabled, Gigmeout will collect, store, and use your device\'s precise location, such as your GPS information. This lets us improve your experience - For example, showing you more local itemmates, content, ads, and recommendations.',
//           ),
//           SettingRowWidget(
//               GigTranslationConstants.privacyAndPolicy.tr,
//               showDivider: true,
//               onPressed: (){
//                 GigUtilities.launchURL("https://gigmeout.io/politica-de-privacidad/");
//               }
//           ),
//         ],
//       ),),
//     );
//   }
// }
