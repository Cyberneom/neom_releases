
abstract class QuotationService {

  void setAppItemSize(String selectedSize);
  void setAppItemDuration();
  void setAppItemQty();
  void setProcessARequired();
  void setProcessBRequired();
  void setCoverDesignRequired();
  void updateQuotation();
  void addRevenuePercentage();
  Future<void> sendWhatsappQuotation();
  void setPaperType(String selectedType);
  void setCoverLamination(String selectedLamination);
  void setOnlyPrinting();
  void setOnlyDigital();
  void setFlapRequired();

}
