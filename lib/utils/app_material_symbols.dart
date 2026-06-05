import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Project-owned Material Symbols constants that must survive release font
/// subsetting. Keep font family/package literals visible to Flutter's tree
/// shaker.
abstract final class AppMaterialSymbols {
  AppMaterialSymbols._();

  static const IconData vitalSigns = IconData(
    0xe650,
    fontFamily: 'MaterialSymbolsOutlined',
    fontPackage: 'material_symbols_icons',
  );
}

class VitalSignsIcon extends StatelessWidget {
  const VitalSignsIcon({super.key, this.size, this.color});

  static const String _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -960 960 960">
  <path d="M360-160q-19 0-34-11t-22-28l-92-241H40v-80h228l92 244 184-485q7-17 22-28t34-11q19 0 34 11t22 28l92 241h172v80H692l-92-244-184 485q-7 17-22 28t-34 11Z"/>
</svg>
''';

  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final resolvedSize = size ?? iconTheme.size ?? 24;
    final resolvedColor = color ?? iconTheme.color ?? Colors.black;

    return SvgPicture.string(
      _svg,
      width: resolvedSize,
      height: resolvedSize,
      colorFilter: ColorFilter.mode(resolvedColor, BlendMode.srcIn),
      excludeFromSemantics: true,
    );
  }
}
