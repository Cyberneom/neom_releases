enum WooOrderStatus {
  pending('pending'),
  processing('processing'),
  onHold('on-hold'),
  completed('completed'),
  cancelled('cancelled'),
  refunded('refunded'),
  failed('failed'),
  autoDraft('auto-draft'),
  checkoutDraft('checkout-draft'),
  nupaleSession('nupale-session');

  final String value;
  const WooOrderStatus(this.value);

}
