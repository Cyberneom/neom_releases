enum TransactionType {
  deposit(0), //AppBank to user
  coupon(1), //AppBank to user
  loyaltyPoints(2), //AppBank to User
  refund(3), //AppBank to user

  withdrawal(4), //User to App Bank
  purchase(5), //User to AppBank
  transfer(6); //User to User

  final int value;
  const TransactionType(this.value);
}
