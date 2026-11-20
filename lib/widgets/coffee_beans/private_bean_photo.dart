import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../database/database.dart';
import '../../services/bean_photo_service.dart';

/// Resolves an owned photo only while rendering it. Signed URLs are kept in
/// memory and never passed back to the bean record or disk image cache.
class PrivateBeanPhoto extends StatefulWidget {
  const PrivateBeanPhoto({
    super.key,
    required this.reference,
    required this.beanId,
    required this.fallback,
    this.loading,
    this.height,
    this.width,
    required this.fit,
  });

  final String reference;
  final String beanId;
  final Widget fallback;
  final Widget? loading;
  final double? height;
  final double? width;
  final BoxFit fit;

  @override
  State<PrivateBeanPhoto> createState() => _PrivateBeanPhotoState();
}

class _PrivateBeanPhotoState extends State<PrivateBeanPhoto> {
  AppDatabase? _database;
  Future<String?>? _url;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final database = context.watch<AppDatabase?>();
    if (!identical(database, _database)) {
      _database = database;
      _load();
    }
  }

  @override
  void didUpdateWidget(PrivateBeanPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reference != widget.reference ||
        oldWidget.beanId != widget.beanId) {
      _load();
    }
  }

  void _load() {
    final database = _database;
    _url = database == null
        ? null
        : BeanPhotoService.forDatabase(
            database,
          ).readUrl(widget.reference, widget.beanId);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<String?>(
    future: _url,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return widget.loading ?? widget.fallback;
      }
      final url = snapshot.data;
      if (url == null) return widget.fallback;
      return Image.network(
        url,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (_, _, _) => widget.fallback,
      );
    },
  );
}
