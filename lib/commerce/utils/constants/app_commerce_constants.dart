class AppCommerceConstants {

  static const int minDuration = 25;
  static const int maxDuration = 500;
  static const int minQty = 20;
  static const int maxQty = 1000;

  static Map<String, double> appCoinsQty = {
    "app_coins_10": 50,
    "app_coins_20": 100,
    "app_coins_50": 250,
    "app_coins_100": 500,
  };

  static Map<String, double> eventCoverLevels = {
    "event_cover_level_0": 0,
    "event_cover_level_1": 50,
    "event_cover_level_2": 100,
    "event_cover_level_3": 150,
    "event_cover_level_4": 200,
  };

  ///This info is needed for quotations.
  static const double revenuePercentage = 0.25; ///Revenue percentage from service
  static const int processACost = 20; ///Cost Per Unit of Duration
  static const int processBCost = 30; ///Cost Per Unit of Duration
  static const int coverDesignCost = 1500;
  static const int coverPrint = 15;  ///Cost Per Unit
  static const double costPerDurationUnit = 0.7; ///Cost Retrieved from BookDepot
  static const double durationConvertionPerSize = 2.20; ///Converting size from Big to Small

}
