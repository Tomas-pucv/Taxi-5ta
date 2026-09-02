import 'package:flutter/material.dart';

import 'package:taxi1/config/map_config.dart';

/// Miniatura real del estilo de mapa: una tesela de MapTiler centrada en
/// Quilpué, la misma cartografía que verá el usuario.
///
/// Trae una sola imagen en vez de instanciar un `FlutterMap` de verdad. Además
/// degrada con dignidad: el informe insiste en que la app debe seguir siendo
/// usable con conectividad intermitente (RNF-03-01), así que si la tesela no
/// llega, el selector muestra un marcador de posición en vez de un hueco roto.
class MapStyleThumbnail extends StatelessWidget {
  const MapStyleThumbnail({super.key, required this.style});

  final MapStyle style;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Image.network(
      mapTileThumbnailUrl(style, isDark: isDark),
      fit: BoxFit.cover,
      // Sin esto la imagen aparece de golpe y el selector "parpadea".
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 200),
          child: child,
        );
      },
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return ColoredBox(
          color: scheme.surfaceContainerHighest,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stack) => _Placeholder(style: style),
    );
  }
}

/// Sustituto cuando no hay red: sugiere el estilo con icono y color en vez de
/// dejar el recuadro vacío.
class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.style});

  final MapStyle style;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final satellite = style == MapStyle.satellite;

    return ColoredBox(
      color: satellite ? scheme.inverseSurface : scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          satellite ? Icons.satellite_alt : Icons.map_outlined,
          size: 32,
          color: satellite ? scheme.onInverseSurface : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
