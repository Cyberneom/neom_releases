import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:sint/sint.dart';

import '../../../utils/constants/release_translation_constants.dart';
import '../release_upload_web_controller.dart';

/// Phase for Physical Sale / Dropshipping configuration.
/// Can be skipped with one click if the user only publishes digital content.
class ReleasePhysicalSalePhase extends StatelessWidget {
  final ReleaseUploadWebController controller;

  const ReleasePhysicalSalePhase({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final ctrl = controller;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header title + description
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColor.bondiBlue.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.local_shipping_outlined, color: AppColor.bondiBlue, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ReleaseTranslationConstants.dropshippingTitle.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ReleaseTranslationConstants.dropshippingSubtitle.tr,
                          style: TextStyle(color: Colors.grey[400], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Master Switch Card
              Obx(() => Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: ctrl.isPhysical.value
                      ? AppColor.bondiBlue.withAlpha(15)
                      : Colors.white.withAlpha(6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ctrl.isPhysical.value
                        ? AppColor.bondiBlue.withAlpha(80)
                        : Colors.white.withAlpha(15),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ReleaseTranslationConstants.enableDropshipping.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ReleaseTranslationConstants.physicalSaleDescMsg.tr,
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Switch.adaptive(
                      value: ctrl.isPhysical.value,
                      activeColor: AppColor.bondiBlue,
                      onChanged: (v) => ctrl.isPhysical.value = v,
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 20),

              // Expanded configuration when physical sale is enabled
              Obx(() {
                if (!ctrl.isPhysical.value) {
                  return _buildInactivePlaceholder(context, ctrl);
                }
                return _buildActiveConfiguration(context, ctrl);
              }),
            ],
          ),
        ),
      ),
    );
  }

  /// Placeholder when physical dropshipping is disabled
  Widget _buildInactivePlaceholder(BuildContext context, ReleaseUploadWebController ctrl) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(10)),
      ),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, color: Colors.grey[600], size: 44),
          const SizedBox(height: 12),
          Text(
            'Esta publicación será únicamente digital (eBook / streaming)',
            style: TextStyle(color: Colors.grey[300], fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            'Si no cuentas con ejemplares físicos para entrega directa, puedes continuar al resumen.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.bondiBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: Text(ReleaseTranslationConstants.skipPhysicalSale.tr),
            onPressed: ctrl.goNext,
          ),
        ],
      ),
    );
  }

  /// Active dropshipping details form
  Widget _buildActiveConfiguration(BuildContext context, ReleaseUploadWebController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Price and Shipping Included Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Physical Price
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Precio de venta físico (MXN) *'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: ctrl.physicalPriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'ej. 350.00',
                      hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                      prefixIcon: const Icon(Icons.attach_money, color: Colors.white70, size: 20),
                      filled: true,
                      fillColor: Colors.white.withAlpha(8),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withAlpha(15)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withAlpha(15)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColor.bondiBlue),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Estimated Dispatch Days
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel(ReleaseTranslationConstants.estimatedDispatchDays.tr),
                  const SizedBox(height: 6),
                  TextField(
                    controller: ctrl.shippingDaysController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: ReleaseTranslationConstants.estimatedDispatchDaysHint.tr,
                      hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                      prefixIcon: const Icon(Icons.timer_outlined, color: Colors.white70, size: 20),
                      filled: true,
                      fillColor: Colors.white.withAlpha(8),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withAlpha(15)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withAlpha(15)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColor.bondiBlue),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // 2. Shipping Included Toggle Card
        Obx(() => InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => ctrl.shippingIncluded.value = !ctrl.shippingIncluded.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: ctrl.shippingIncluded.value
                    ? AppColor.bondiBlue.withAlpha(80)
                    : Colors.white.withAlpha(15),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 22, height: 22,
                  child: Checkbox(
                    value: ctrl.shippingIncluded.value,
                    onChanged: (v) => ctrl.shippingIncluded.value = v ?? false,
                    activeColor: AppColor.bondiBlue,
                    side: BorderSide(color: Colors.grey[600]!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ReleaseTranslationConstants.shippingIncludedTitle.tr,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ctrl.shippingIncluded.value
                            ? ReleaseTranslationConstants.shippingIncludedDesc.tr
                            : ReleaseTranslationConstants.shippingQuotedSeparately.tr,
                        style: TextStyle(color: Colors.grey[400], fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )),
        const SizedBox(height: 20),

        // 3. Origin City & State (for empathy & transparency)
        _fieldLabel(ReleaseTranslationConstants.shippingOriginTitle.tr),
        const SizedBox(height: 4),
        Text(
          'Indica la ciudad y estado desde donde envías tus obras para conectar con tus lectores y dar certidumbre a la entrega.',
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: ctrl.shippingCityController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: ReleaseTranslationConstants.shippingCity.tr,
                  labelStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                  hintText: ReleaseTranslationConstants.shippingCityHint.tr,
                  hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                  prefixIcon: const Icon(Icons.location_city_outlined, color: Colors.white70, size: 20),
                  filled: true,
                  fillColor: Colors.white.withAlpha(8),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withAlpha(15)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withAlpha(15)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColor.bondiBlue),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TextField(
                controller: ctrl.shippingStateController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: ReleaseTranslationConstants.shippingState.tr,
                  labelStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                  hintText: ReleaseTranslationConstants.shippingStateHint.tr,
                  hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                  prefixIcon: const Icon(Icons.map_outlined, color: Colors.white70, size: 20),
                  filled: true,
                  fillColor: Colors.white.withAlpha(8),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withAlpha(15)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withAlpha(15)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColor.bondiBlue),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),

        // 4. Recommendation Card: Correos de México (Mexpost)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColor.bondiBlue.withAlpha(12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColor.bondiBlue.withAlpha(45)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColor.bondiBlue.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.markunread_mailbox_outlined, color: AppColor.bondiBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ReleaseTranslationConstants.correosDeMexicoTitle.tr,
                      style: TextStyle(
                        color: AppColor.bondiBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ReleaseTranslationConstants.correosDeMexicoDesc.tr,
                      style: TextStyle(color: Colors.grey[300], fontSize: 12, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 5. Actions row
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: ctrl.skipPhysicalSale,
              child: Text(
                ReleaseTranslationConstants.skipPhysicalSale.tr,
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.bondiBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: ctrl.goNext,
              child: Text(
                AppTranslationConstants.next.tr,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
    );
  }
}
