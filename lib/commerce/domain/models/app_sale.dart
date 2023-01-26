
class AppSale {

  String id;
  int orderNumber;
  List<String> orderIds;

  AppSale({
    this.id = "",
    this.orderNumber = 0,
    this.orderIds = const []
  });

  @override
  String toString() {
    return 'AppSales{id: $id, orderNumber: $orderNumber}';
  }

  AppSale.fromJSON(data) :
        id = data["id"] ?? "",
        orderNumber = data["orderNumber"] ?? 0,
        orderIds = data["orderIds"]?.cast<String>() ?? [];


  Map<String, dynamic> toJSON() {
    return <String, dynamic> {
      'orderNumber': orderNumber,
      'orderIds': orderIds
    };
  }

}
