import 'package:flutter/material.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:sint/sint.dart';

import 'release_upload_web_modal.dart';

/// Wrapper page for web that immediately opens the modal overlay.
/// This page shows the home background and opens the modal on top.
class ReleaseUploadWebPage extends StatefulWidget {
  const ReleaseUploadWebPage({super.key});

  @override
  State<ReleaseUploadWebPage> createState() => _ReleaseUploadWebPageState();
}

class _ReleaseUploadWebPageState extends State<ReleaseUploadWebPage> {

  @override
  void initState() {
    super.initState();
    // Open modal after frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ReleaseUploadWebModal.show(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Transparent scaffold — the modal is the main content
    return Scaffold(
      backgroundColor: AppFlavour.getBackgroundColor(),
      body: Container(
        decoration: AppTheme.appBoxDecoration,
        child: Center(
          child: GestureDetector(
            onTap: () => Sint.back(),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}
