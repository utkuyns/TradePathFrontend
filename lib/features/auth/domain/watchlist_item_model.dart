class WatchlistItemModel {
  final String symbol;
  final String companyName;
  double currentPrice;
  double priceChange;
  double priceChangePercentage;
  final List<double> sparkline;

  WatchlistItemModel({
    required this.symbol,
    required this.companyName,
    required this.currentPrice,
    required this.priceChange,
    required this.priceChangePercentage,
    required this.sparkline,
  });

  factory WatchlistItemModel.fromJson(Map<String, dynamic> json) {
    double safeDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return WatchlistItemModel(
      symbol: json['symbol'] ?? '',
      companyName: json['companyName'] ?? '',
      currentPrice: safeDouble(json['currentPrice']),
      priceChange: safeDouble(json['priceChange']),
      priceChangePercentage: safeDouble(json['priceChangePercentage']),
      sparkline: [], // fromJson ile gelmiyor, ayrı çekilecek
    );
  }
} 