import 'package:enum_to_string/enum_to_string.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:neom_commons/auth/ui/login/login_controller.dart';
import 'package:neom_commons/core/data/implementations/geolocator_controller.dart';
import 'package:neom_commons/core/data/implementations/shared_preference_controller.dart';
import 'package:neom_commons/core/data/implementations/user_controller.dart';
import 'package:neom_commons/core/utils/app_utilities.dart';
import 'package:neom_commons/core/utils/constants/app_page_id_constants.dart';
import 'package:neom_commons/core/utils/constants/app_translation_constants.dart';
import 'package:neom_commons/core/utils/enums/app_locale.dart';

class CommerceServicesController extends GetxController {

  var logger = AppUtilities.logger;
  final loginController = Get.find<LoginController>();
  final userController = Get.find<UserController>();

  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool isLoading) => _isLoading.value = isLoading;


  @override
  void onInit() async {
    super.onInit();
    logger.d("Settings Controller Init");
    isLoading = false;
  }

}
