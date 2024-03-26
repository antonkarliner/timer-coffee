// lib/models/vendor_model.dart
class VendorModel {
  final String vendorId;
  final String vendorName;
  final String vendorDescription;
  final String? bannerUrl;
  final bool active;

  VendorModel({
    required this.vendorId,
    required this.vendorName,
    required this.vendorDescription,
    this.bannerUrl,
    required this.active,
  });
}
