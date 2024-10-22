class AppQuotation {

  String id;
  String from;
  String to;
  String productId;

  int processACost;
  int processBCost;
  int processCCost;
  int coverDesignCost;
  int prePrintCost;

  int minDuration;
  int maxDuration;
  double minCostPerDurationUnit;
  double midCostPerDurationUnit;
  double maxCostPerDurationUnit;
  double durationConvertionPerSize;

  int minQty;
  int midQty;
  int maxQty;
  int coverPrint;
  double costPerFlap;

  double tax;
  double revenuePercentage;

  double lowQualityRelation;
  double highQualityRelation;

  double lowSizeRelation;
  double highSizeRelation;

  // Constructor con valores por defecto tomados de AppQuotationConstants
  AppQuotation({
    this.id = '',
    this.from = '',
    this.to = '',
    this.productId = '',
    this.processACost = 15,
    this.processBCost = 20,
    this.processCCost = 0,
    this.coverDesignCost = 1500,
    this.prePrintCost = 600,
    this.minDuration = 25,
    this.maxDuration = 500,
    this.minCostPerDurationUnit = 0.35,
    this.midCostPerDurationUnit = 0.50,
    this.maxCostPerDurationUnit = 0.65,
    this.durationConvertionPerSize = 1.75,
    this.minQty = 20,
    this.midQty = 100,
    this.maxQty = 1000,
    this.coverPrint = 15,
    this.costPerFlap = 6.0,
    this.tax = 0.16,
    this.revenuePercentage = 0.18,
    this.lowQualityRelation = 0.8,
    this.highQualityRelation = 1.5,
    this.lowSizeRelation = 1.2,
    this.highSizeRelation = 1.5
  });

  // Método fromJson para crear una instancia desde un mapa (JSON)
  factory AppQuotation.fromJson(Map<String, dynamic> json) {
    return AppQuotation(
      id: json['id'] ?? '',
      from: json['from'] ?? '',
      to: json['to'] ?? '',
      productId: json['productId'] ?? '',
      processACost: json['processACost'] ?? 15,
      processBCost: json['processBCost'] ?? 20,
      processCCost: json['processCCost'] ?? 0,
      coverDesignCost: json['coverDesignCost'] ?? 1500,
      prePrintCost: json['prePrintCost'] ?? 600,
      minDuration: json['minDuration'] ?? 25,
      maxDuration: json['maxDuration'] ?? 500,
      minCostPerDurationUnit: json['minCostPerDurationUnit'] ?? 0.35,
      midCostPerDurationUnit: json['midCostPerDurationUnit'] ?? 0.50,
      maxCostPerDurationUnit: json['maxCostPerDurationUnit'] ?? 0.65,
      durationConvertionPerSize: json['durationConvertionPerSize'] ?? 1.75,
      minQty: json['minQty'] ?? 20,
      midQty: json['midQty'] ?? 100,
      maxQty: json['maxQty'] ?? 1000,
      coverPrint: json['coverPrint'] ?? 15,
      costPerFlap: double.tryParse(json['costPerFlap'].toString()) ?? 6.0,
      tax: json['tax'] ?? 0.16,
      revenuePercentage: json['revenuePercentage'] ?? 0.18,
      lowQualityRelation: json['lowQualityRelation'] ?? 0.8,
      highQualityRelation: json['highQualityRelation'] ?? 1.5,
      lowSizeRelation: json['lowSizeRelation'] ?? 1.2,
      highSizeRelation: json['highSizeRelation'] ?? 1.5,
    );
  }

  // Método toJson para convertir la instancia a un mapa (JSON)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from': from,
      'to': to,
      'productId': productId,
      'processACost': processACost,
      'processBCost': processBCost,
      'processCCost': processCCost,
      'coverDesignCost': coverDesignCost,
      'prePrintCost': prePrintCost,
      'minDuration': minDuration,
      'maxDuration': maxDuration,
      'minCostPerDurationUnit': minCostPerDurationUnit,
      'midCostPerDurationUnit': midCostPerDurationUnit,
      'maxCostPerDurationUnit': maxCostPerDurationUnit,
      'durationConvertionPerSize': durationConvertionPerSize,
      'minQty': minQty,
      'midQty': midQty,
      'maxQty': maxQty,
      'coverPrint': coverPrint,
      'costPerFlap': costPerFlap,
      'tax': tax,
      'revenuePercentage': revenuePercentage,
      'lowQualityRelation': lowQualityRelation,
      'highQualityRelation': highQualityRelation,
      'lowSizeRelation': lowSizeRelation,
      'highSizeRelation': highSizeRelation,
    };
  }
}
