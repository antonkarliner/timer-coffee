// lib/database/vendors_dao.dart
part of 'database.dart';

@DriftAccessor(tables: [Vendors])
class VendorsDao extends DatabaseAccessor<AppDatabase> with _$VendorsDaoMixin {
  final AppDatabase db;

  VendorsDao(this.db) : super(db);

  // Retrieve all active vendors
  Future<List<VendorModel>> getAllActiveVendors() async {
    final query = select(vendors)..where((tbl) => tbl.active.equals(true));
    final result = await query.get();
    return result
        .map((row) => VendorModel(
              vendorId: row.vendorId,
              vendorName: row.vendorName,
              vendorDescription: row.vendorDescription,
              bannerUrl: row.bannerUrl,
              active: row.active,
            ))
        .toList();
  }

  // Retrieve vendor by ID
  Future<VendorModel?> getVendorById(String vendorId) async {
    final query = select(vendors)
      ..where((tbl) => tbl.vendorId.equals(vendorId));
    final row = await query.getSingleOrNull();
    if (row != null) {
      return VendorModel(
        vendorId: row.vendorId,
        vendorName: row.vendorName,
        vendorDescription: row.vendorDescription,
        bannerUrl: row.bannerUrl,
        active: row.active,
      );
    }
    return null;
  }
}
