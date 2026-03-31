import 'package:flutter/material.dart';
import 'package:neom_commons/app_flavour.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_core/utils/enums/release_type.dart';
import 'package:sint/sint.dart';

import '../../../utils/constants/release_translation_constants.dart';
import '../release_upload_web_controller.dart';

/// Phase 0: Choose release type — Single or Album (with subtypes).
class ReleaseTypePhase extends StatelessWidget {
  final ReleaseUploadWebController controller;

  const ReleaseTypePhase({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final subtypes = AppFlavour.getAlbumSubtypes();

    return Center(
      child: SingleChildScrollView(
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

            // Single card
            _TypeCard(
              icon: AppFlavour.getSingleIcon(),
              title: AppFlavour.getSingleTypeName().tr,
              description: AppFlavour.getSingleTypeDesc().tr,
              onTap: () => controller.selectType(ReleaseType.single),
              fullWidth: true,
            ),
            const SizedBox(height: 24),

            // Album subtypes header
            if (subtypes.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.white.withAlpha(20))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      AppFlavour.getAlbumTypeName().tr,
                      style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.white.withAlpha(20))),
                ],
              ),
              const SizedBox(height: 16),

              // Album subtype cards in a wrap
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: subtypes.map((sub) => _TypeCard(
                  icon: sub.icon,
                  title: sub.nameKey.tr,
                  description: sub.descKey.tr,
                  onTap: () => controller.selectType(ReleaseType.album, subtype: sub.type),
                  compact: subtypes.length > 2,
                )).toList(),
              ),
            ],
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
  final bool fullWidth;
  final bool compact;

  const _TypeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.fullWidth = false,
    this.compact = false,
  });

  @override
  State<_TypeCard> createState() => _TypeCardState();
}

class _TypeCardState extends State<_TypeCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cardWidth = widget.fullWidth
        ? MediaQuery.of(context).size.width.clamp(200.0, 540.0)
        : widget.compact ? 200.0 : 260.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: cardWidth,
          padding: EdgeInsets.all(widget.compact ? 20 : 28),
          decoration: BoxDecoration(
            color: _hovered ? Colors.white.withAlpha(12) : Colors.white.withAlpha(5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered ? AppColor.bondiBlue.withAlpha(120) : Colors.white.withAlpha(20),
              width: 1.5,
            ),
          ),
          child: widget.fullWidth
              ? Row(
                  children: [
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColor.bondiBlue.withAlpha(80), width: 2),
                      ),
                      child: Icon(widget.icon, color: AppColor.bondiBlue, size: 30),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(widget.description, style: TextStyle(color: Colors.grey[400], fontSize: 13, height: 1.4)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: widget.compact ? 56 : 72,
                      height: widget.compact ? 56 : 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColor.bondiBlue.withAlpha(80), width: 2),
                      ),
                      child: Icon(widget.icon, color: AppColor.bondiBlue, size: widget.compact ? 28 : 36),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: widget.compact ? 15 : 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[400], fontSize: widget.compact ? 12 : 13, height: 1.4),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
