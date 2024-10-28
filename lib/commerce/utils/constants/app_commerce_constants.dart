class AppCommerceConstants {

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

  static List<int> appReleaseItemsQty = List<int>.generate(15, (index) => index + 1);

  static int trialPeriodDays = 30;
}
