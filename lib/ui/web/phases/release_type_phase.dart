import 'package:flutter/material.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:neom_core/utils/enums/release_type.dart';
import 'package:sint/sint.dart';

import '../../../utils/constants/release_translation_constants.dart';
import '../release_upload_web_controller.dart';

/// Phase 1: Choose release type (Single or Album) — eMastered style cards.
class ReleaseTypePhase extends StatelessWidget {
  final ReleaseUploadWebController controller;

  const ReleaseTypePhase({super.key, required this.controller});

  bool get _isEmxi => AppConfig.instance.appInUse == AppInUse.e;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              ReleaseTranslationConstants.whatToUpload.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ReleaseTranslationConstants.chooseOption.tr,
              style: TextStyle(color: Colors.grey[400], fontSize: 15),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _TypeCard(
                  icon: _isEmxi ? Icons.menu_book_outlined : Icons.music_note_outlined,
                  title: AppFlavour.getSingleTypeName().tr,
                  description: AppFlavour.getSingleTypeDesc().tr,
                  onTap: () => controller.selectType(ReleaseType.single),
                ),
                const SizedBox(width: 24),
                _TypeCard(
                  icon: _isEmxi ? Icons.headphones_outlined : Icons.album_outlined,
                  title: AppFlavour.getAlbumTypeName().tr,
                  description: AppFlavour.getAlbumTypeDesc().tr,
                  onTap: () => controller.selectType(ReleaseType.album),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _TypeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  State<_TypeCard> createState() => _TypeCardState();
}

class _TypeCardState extends State<_TypeCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 260,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _hovered ? Colors.white.withAlpha(12) : Colors.white.withAlpha(5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered ? AppColor.bondiBlue.withAlpha(120) : Colors.white.withAlpha(20),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColor.bondiBlue.withAlpha(80), width: 2),
                ),
                child: Icon(widget.icon, color: AppColor.bondiBlue, size: 36),
              ),
              const SizedBox(height: 20),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.description,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400], fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
