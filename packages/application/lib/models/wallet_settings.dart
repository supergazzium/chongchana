// ignore_for_file: non_constant_identifier_names

class WalletSettings {
  late PointConversion pointConversion;
  late TransferSettings transfer;
  late BillboardSettings billboard;

  WalletSettings({
    PointConversion? pointConversion,
    TransferSettings? transfer,
    BillboardSettings? billboard,
  }) {
    this.pointConversion = pointConversion ?? PointConversion();
    this.transfer = transfer ?? TransferSettings();
    this.billboard = billboard ?? BillboardSettings();
  }

  WalletSettings.fromJson(Map<String, dynamic> json) {
    pointConversion = json['pointConversion'] != null
        ? PointConversion.fromJson(json['pointConversion'])
        : PointConversion();
    transfer = json['transfer'] != null
        ? TransferSettings.fromJson(json['transfer'])
        : TransferSettings();
    billboard = json['billboard'] != null
        ? BillboardSettings.fromJson(json['billboard'])
        : BillboardSettings();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['pointConversion'] = pointConversion.toJson();
    data['transfer'] = transfer.toJson();
    data['billboard'] = billboard.toJson();
    return data;
  }
}

class PointConversion {
  late double rate;
  late int minimumRedemption;
  late bool requiresApproval;

  PointConversion({
    double? rate,
    int? minimumRedemption,
    bool? requiresApproval,
  }) {
    this.rate = rate ?? 1.0;
    this.minimumRedemption = minimumRedemption ?? 100;
    this.requiresApproval = requiresApproval ?? false;
  }

  PointConversion.fromJson(Map<String, dynamic> json) {
    rate = (json['rate'] is int)
        ? (json['rate'] as int).toDouble()
        : (json['rate'] ?? 1.0).toDouble();
    minimumRedemption = json['minimumRedemption'] ?? 100;
    requiresApproval = json['requiresApproval'] ?? false;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['rate'] = rate;
    data['minimumRedemption'] = minimumRedemption;
    data['requiresApproval'] = requiresApproval;
    return data;
  }
}

class TransferSettings {
  late double feePercentage;
  late double feeFixed;
  late double minAmount;
  late double maxAmount;
  late double dailyLimit;

  TransferSettings({
    double? feePercentage,
    double? feeFixed,
    double? minAmount,
    double? maxAmount,
    double? dailyLimit,
  }) {
    this.feePercentage = feePercentage ?? 0.0;
    this.feeFixed = feeFixed ?? 0.0;
    this.minAmount = minAmount ?? 1.0;
    this.maxAmount = maxAmount ?? 50000.0;
    this.dailyLimit = dailyLimit ?? 100000.0;
  }

  TransferSettings.fromJson(Map<String, dynamic> json) {
    feePercentage = (json['feePercentage'] is int)
        ? (json['feePercentage'] as int).toDouble()
        : (json['feePercentage'] ?? 0.0).toDouble();
    feeFixed = (json['feeFixed'] is int)
        ? (json['feeFixed'] as int).toDouble()
        : (json['feeFixed'] ?? 0.0).toDouble();
    minAmount = (json['minAmount'] is int)
        ? (json['minAmount'] as int).toDouble()
        : (json['minAmount'] ?? 1.0).toDouble();
    maxAmount = (json['maxAmount'] is int)
        ? (json['maxAmount'] as int).toDouble()
        : (json['maxAmount'] ?? 50000.0).toDouble();
    dailyLimit = (json['dailyLimit'] is int)
        ? (json['dailyLimit'] as int).toDouble()
        : (json['dailyLimit'] ?? 100000.0).toDouble();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['feePercentage'] = feePercentage;
    data['feeFixed'] = feeFixed;
    data['minAmount'] = minAmount;
    data['maxAmount'] = maxAmount;
    data['dailyLimit'] = dailyLimit;
    return data;
  }

  /// Calculate transfer fee for a given amount
  double calculateFee(double amount) {
    return (amount * feePercentage / 100) + feeFixed;
  }

  /// Calculate total amount including fee
  double calculateTotalWithFee(double amount) {
    return amount + calculateFee(amount);
  }
}

class BillboardSettings {
  late bool enabled;
  late List<BillboardImage> images;
  late int autoPlayInterval;

  BillboardSettings({
    bool? enabled,
    List<BillboardImage>? images,
    int? autoPlayInterval,
  }) {
    this.enabled = enabled ?? false;
    this.images = images ?? [];
    this.autoPlayInterval = autoPlayInterval ?? 5000;
  }

  BillboardSettings.fromJson(Map<String, dynamic> json) {
    enabled = json['enabled'] ?? false;
    if (json['images'] != null) {
      images = <BillboardImage>[];
      json['images'].forEach((v) {
        images.add(BillboardImage.fromJson(v));
      });
    } else {
      images = [];
    }
    autoPlayInterval = json['autoPlayInterval'] ?? 5000;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['enabled'] = enabled;
    data['images'] = images.map((v) => v.toJson()).toList();
    data['autoPlayInterval'] = autoPlayInterval;
    return data;
  }
}

class BillboardImage {
  late String imageUrl;
  late String? linkUrl;
  late int order;
  late int? width;
  late int? height;

  BillboardImage({
    required this.imageUrl,
    this.linkUrl,
    int? order,
    this.width,
    this.height,
  }) {
    this.order = order ?? 0;
  }

  BillboardImage.fromJson(Map<String, dynamic> json) {
    imageUrl = json['imageUrl'];
    linkUrl = json['linkUrl'];
    order = json['order'] ?? 0;
    width = json['width'];
    height = json['height'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['imageUrl'] = imageUrl;
    data['linkUrl'] = linkUrl;
    data['order'] = order;
    data['width'] = width;
    data['height'] = height;
    return data;
  }
}