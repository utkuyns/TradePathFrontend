class PortfolioItemModel {
  final String symbol;
  final String companyName;
  final int quantity;
  final double currentPrice;
  final double totalValue;
  final double purchasePrice;

  PortfolioItemModel({
    required this.symbol,
    required this.companyName,
    required this.quantity,
    required this.currentPrice,
    required this.totalValue,
    required this.purchasePrice,
  });

  factory PortfolioItemModel.fromJson(Map<String, dynamic> json) {
    double safeDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return PortfolioItemModel(
      symbol: json['symbol'] ?? '',
      companyName: json['companyName'] ?? '',
      quantity: json['quantity'] ?? 0,
      currentPrice: safeDouble(json['currentPrice']),
      totalValue: safeDouble(json['totalValue']),
      purchasePrice: safeDouble(json['purchasePrice']),
    );
  }
} 