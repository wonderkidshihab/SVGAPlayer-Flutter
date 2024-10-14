part of 'player.dart';

class _SVGAPainter extends CustomPainter {
  final BoxFit fit;
  final SVGAAnimationController controller;
  int get currentFrame => controller.currentFrame;
  MovieEntity get videoItem => controller.videoItem!;
  final FilterQuality filterQuality;
  final bool clipRect;

  final HashMap<String, Path> _pathCache = HashMap<String, Path>();
  final HashMap<String, Float64List> _transformCache =
      HashMap<String, Float64List>();

  _SVGAPainter(
    this.controller, {
    this.fit = BoxFit.contain,
    this.filterQuality = FilterQuality.low,
    this.clipRect = true,
  })  : assert(
            controller.videoItem != null, 'Invalid SVGAAnimationController!'),
        super(repaint: controller) {
    _precalculateTransforms();
  }

  void _precalculateTransforms() {
    for (final sprite in videoItem.sprites) {
      for (final frameItem in sprite.frames) {
        if (frameItem.hasTransform()) {
          _transformCache[sprite.imageKey] = Float64List.fromList(<double>[
            frameItem.transform.a,
            frameItem.transform.b,
            0.0,
            0.0,
            frameItem.transform.c,
            frameItem.transform.d,
            0.0,
            0.0,
            0.0,
            0.0,
            1.0,
            0.0,
            frameItem.transform.tx,
            frameItem.transform.ty,
            0.0,
            1.0
          ]);
        }
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (controller._canvasNeedsClear) {
      controller._canvasNeedsClear = false;
      return;
    }
    if (size.isEmpty || controller.videoItem == null) return;
    final params = videoItem.params;
    final Size viewBoxSize = Size(params.viewBoxWidth, params.viewBoxHeight);
    if (viewBoxSize.isEmpty) return;

    canvas.save();
    try {
      final canvasRect = Offset.zero & size;
      if (clipRect) canvas.clipRect(canvasRect, doAntiAlias: false);
      _scaleCanvasToViewBox(canvas, canvasRect, Offset.zero & viewBoxSize);
      _drawSprites(canvas, size);
    } finally {
      canvas.restore();
    }
  }

  void _scaleCanvasToViewBox(Canvas canvas, Rect canvasRect, Rect viewBoxRect) {
    final fittedSizes = applyBoxFit(fit, viewBoxRect.size, canvasRect.size);
    var sx = fittedSizes.destination.width / fittedSizes.source.width;
    var sy = fittedSizes.destination.height / fittedSizes.source.height;
    final Size scaledHalfViewBoxSize =
        Size(viewBoxRect.size.width * sx, viewBoxRect.size.height * sy) / 2.0;
    final Size halfCanvasSize = canvasRect.size / 2.0;
    final Offset shift = Offset(
      halfCanvasSize.width - scaledHalfViewBoxSize.width,
      halfCanvasSize.height - scaledHalfViewBoxSize.height,
    );
    if (shift != Offset.zero) canvas.translate(shift.dx, shift.dy);
    if (sx != 1.0 && sy != 1.0) canvas.scale(sx, sy);
  }

  void _drawSprites(Canvas canvas, Size size) {
    final dynamicItem = videoItem.dynamicItem;
    final dynamicImages =
        HashMap<String, ui.Image>.from(dynamicItem.dynamicImages);
    final dynamicDrawer =
        HashMap<String, Function>.from(dynamicItem.dynamicDrawer);
    final dynamicHidden = HashMap<String, bool>.from(dynamicItem.dynamicHidden);

    for (final sprite in videoItem.sprites) {
      final imageKey = sprite.imageKey;
      if (imageKey.isEmpty || dynamicHidden[imageKey] == true) {
        continue;
      }
      final frameItem = sprite.frames[currentFrame];
      final needTransform = frameItem.hasTransform();
      final needClip = frameItem.hasClipPath();

      if (needTransform) {
        canvas.save();
        canvas.transform(_transformCache[sprite.imageKey]!);
      }
      if (needClip) {
        canvas.save();
        canvas.clipPath(_buildDPath(frameItem.clipPath));
      }

      final frameRect = Rect.fromLTRB(
        0,
        0,
        frameItem.layout.width,
        frameItem.layout.height,
      );
      final frameAlpha =
          frameItem.hasAlpha() ? (frameItem.alpha * 255).toInt() : 255;

      _drawBitmap(canvas, imageKey, frameRect, frameAlpha, dynamicImages);
      _drawShape(canvas, frameItem.shapes, frameAlpha);

      final drawer = dynamicDrawer[imageKey];
      if (drawer != null) {
        drawer(canvas, currentFrame);
      }

      if (needClip) {
        canvas.restore();
      }
      if (needTransform) {
        canvas.restore();
      }
    }
  }

  void _drawBitmap(
    Canvas canvas,
    String imageKey,
    Rect frameRect,
    int alpha,
    HashMap<String, ui.Image> dynamicImages,
  ) {
    final bitmap = dynamicImages[imageKey] ?? videoItem.bitmapCache[imageKey];
    if (bitmap == null) return;

    final bitmapPaint = Paint()
      ..filterQuality = filterQuality
      ..isAntiAlias = true
      ..color = Color.fromARGB(alpha, 0, 0, 0);

    final srcRect = Rect.fromLTRB(
      0,
      0,
      bitmap.width.toDouble(),
      bitmap.height.toDouble(),
    );

    canvas.drawImageRect(bitmap, srcRect, frameRect, bitmapPaint);
    _drawTextOnBitmap(canvas, imageKey, frameRect, alpha);
  }

  void _drawShape(
    Canvas canvas,
    List<ShapeEntity> shapes,
    int frameAlpha,
  ) {
    if (shapes.isEmpty) return;

    final Paint fillPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;

    final Paint strokePaint = Paint()..style = PaintingStyle.stroke;

    for (var shape in shapes) {
      final path = _buildPath(shape);
      if (shape.hasTransform()) {
        canvas.save();
        canvas.transform(Float64List.fromList(<double>[
          shape.transform.a,
          shape.transform.b,
          0.0,
          0.0,
          shape.transform.c,
          shape.transform.d,
          0.0,
          0.0,
          0.0,
          0.0,
          1.0,
          0.0,
          shape.transform.tx,
          shape.transform.ty,
          0.0,
          1.0
        ]));
      }

      final fill = shape.styles.fill;
      if (fill.isInitialized()) {
        fillPaint.color = Color.fromARGB(
          (fill.a * frameAlpha).toInt(),
          (fill.r * 255).toInt(),
          (fill.g * 255).toInt(),
          (fill.b * 255).toInt(),
        );
        canvas.drawPath(path, fillPaint);
      }

      final strokeWidth = shape.styles.strokeWidth;
      if (strokeWidth > 0) {
        if (shape.styles.stroke.isInitialized()) {
          strokePaint.color = Color.fromARGB(
            (shape.styles.stroke.a * frameAlpha).toInt(),
            (shape.styles.stroke.r * 255).toInt(),
            (shape.styles.stroke.g * 255).toInt(),
            (shape.styles.stroke.b * 255).toInt(),
          );
        }
        strokePaint.strokeWidth = strokeWidth;
        strokePaint.strokeCap = _getStrokeCap(shape.styles.lineCap);
        strokePaint.strokeJoin = _getStrokeJoin(shape.styles.lineJoin);
        strokePaint.strokeMiterLimit = shape.styles.miterLimit;

        List<double> lineDash = [
          shape.styles.lineDashI,
          shape.styles.lineDashII,
          shape.styles.lineDashIII
        ];
        if (lineDash[0] > 0 || lineDash[1] > 0) {
          canvas.drawPath(
              dashPath(
                path,
                dashArray: CircularIntervalList([
                  lineDash[0] < 1.0 ? 1.0 : lineDash[0],
                  lineDash[1] < 0.1 ? 0.1 : lineDash[1],
                ]),
                dashOffset: DashOffset.absolute(lineDash[2]),
              ),
              strokePaint);
        } else {
          canvas.drawPath(path, strokePaint);
        }
      }

      if (shape.hasTransform()) {
        canvas.restore();
      }
    }
  }

  StrokeCap _getStrokeCap(ShapeEntity_ShapeStyle_LineCap lineCap) {
    switch (lineCap) {
      case ShapeEntity_ShapeStyle_LineCap.LineCap_BUTT:
        return StrokeCap.butt;
      case ShapeEntity_ShapeStyle_LineCap.LineCap_ROUND:
        return StrokeCap.round;
      case ShapeEntity_ShapeStyle_LineCap.LineCap_SQUARE:
        return StrokeCap.square;
      default:
        return StrokeCap.butt;
    }
  }

  StrokeJoin _getStrokeJoin(ShapeEntity_ShapeStyle_LineJoin lineJoin) {
    switch (lineJoin) {
      case ShapeEntity_ShapeStyle_LineJoin.LineJoin_MITER:
        return StrokeJoin.miter;
      case ShapeEntity_ShapeStyle_LineJoin.LineJoin_ROUND:
        return StrokeJoin.round;
      case ShapeEntity_ShapeStyle_LineJoin.LineJoin_BEVEL:
        return StrokeJoin.bevel;
      default:
        return StrokeJoin.miter;
    }
  }

  Path _buildPath(ShapeEntity shape) {
    if (shape.type == ShapeEntity_ShapeType.SHAPE) {
      return _buildDPath(shape.shape.d);
    } else if (shape.type == ShapeEntity_ShapeType.ELLIPSE) {
      final args = shape.ellipse;
      final rect = Rect.fromLTWH(args.x - args.radiusX, args.y - args.radiusY,
          args.radiusX * 2, args.radiusY * 2);
      return Path()..addOval(rect);
    } else if (shape.type == ShapeEntity_ShapeType.RECT) {
      final args = shape.rect;
      final rrect = RRect.fromRectAndRadius(
          Rect.fromLTWH(args.x, args.y, args.width, args.height),
          Radius.circular(args.cornerRadius));
      return Path()..addRRect(rrect);
    }
    return Path();
  }

  static const _validMethods = 'MLHVCSQRZmlhvcsqrz';

  Path _buildDPath(String argD) {
    return _pathCache.putIfAbsent(argD, () {
      final path = Path();
      final d = argD.replaceAllMapped(RegExp('([a-df-zA-Z])'), (match) {
        return "|||${match.group(1)} ";
      }).replaceAll(RegExp(","), " ");

      var currentPoint = Offset.zero;
      Offset? currentPointControl1;
      Offset? currentPointControl2;

      for (final segment in d.split("|||")) {
        if (segment.isEmpty) continue;
        final firstLetter = segment[0];
        if (!_validMethods.contains(firstLetter)) continue;

        final args = segment
            .substring(1)
            .trim()
            .split(" ")
            .map((e) => double.tryParse(e) ?? 0.0)
            .toList();

        switch (firstLetter) {
          case 'M':
            currentPoint = Offset(args[0], args[1]);
            path.moveTo(currentPoint.dx, currentPoint.dy);
            break;
          case 'm':
            currentPoint += Offset(args[0], args[1]);
            path.moveTo(currentPoint.dx, currentPoint.dy);
            break;
          case 'L':
            currentPoint = Offset(args[0], args[1]);
            path.lineTo(currentPoint.dx, currentPoint.dy);
            break;
          case 'l':
            currentPoint += Offset(args[0], args[1]);
            path.lineTo(currentPoint.dx, currentPoint.dy);
            break;
          case 'H':
            currentPoint = Offset(args[0], currentPoint.dy);
            path.lineTo(currentPoint.dx, currentPoint.dy);
            break;
          case 'h':
            currentPoint += Offset(args[0], 0);
            path.lineTo(currentPoint.dx, currentPoint.dy);
            break;
          case 'V':
            currentPoint = Offset(currentPoint.dx, args[0]);
            path.lineTo(currentPoint.dx, currentPoint.dy);
            break;
          case 'v':
            currentPoint += Offset(0, args[0]);
            path.lineTo(currentPoint.dx, currentPoint.dy);
            break;
          case 'C':
            currentPointControl1 = Offset(args[0], args[1]);
            currentPointControl2 = Offset(args[2], args[3]);
            currentPoint = Offset(args[4], args[5]);
            path.cubicTo(
                currentPointControl1.dx,
                currentPointControl1.dy,
                currentPointControl2.dx,
                currentPointControl2.dy,
                currentPoint.dx,
                currentPoint.dy);
            break;
          case 'c':
            currentPointControl1 = currentPoint + Offset(args[0], args[1]);
            currentPointControl2 = currentPoint + Offset(args[2], args[3]);
            currentPoint += Offset(args[4], args[5]);
            path.cubicTo(
                currentPointControl1.dx,
                currentPointControl1.dy,
                currentPointControl2.dx,
                currentPointControl2.dy,
                currentPoint.dx,
                currentPoint.dy);
            break;
          case 'S':
            if (currentPointControl2 != null) {
              currentPointControl1 = currentPoint * 2 - currentPointControl2;
            } else {
              currentPointControl1 = currentPoint;
            }
            currentPointControl2 = Offset(args[0], args[1]);
            currentPoint = Offset(args[2], args[3]);
            path.cubicTo(
                currentPointControl1.dx,
                currentPointControl1.dy,
                currentPointControl2.dx,
                currentPointControl2.dy,
                currentPoint.dx,
                currentPoint.dy);
            break;
          case 's':
            if (currentPointControl2 != null) {
              currentPointControl1 = currentPoint * 2 - currentPointControl2;
            } else {
              currentPointControl1 = currentPoint;
            }
            currentPointControl2 = currentPoint + Offset(args[0], args[1]);
            currentPoint += Offset(args[2], args[3]);
            path.cubicTo(
                currentPointControl1.dx,
                currentPointControl1.dy,
                currentPointControl2.dx,
                currentPointControl2.dy,
                currentPoint.dx,
                currentPoint.dy);
            break;
          case 'Q':
            currentPointControl1 = Offset(args[0], args[1]);
            currentPoint = Offset(args[2], args[3]);
            path.quadraticBezierTo(currentPointControl1.dx,
                currentPointControl1.dy, currentPoint.dx, currentPoint.dy);
            break;
          case 'q':
            currentPointControl1 = currentPoint + Offset(args[0], args[1]);
            currentPoint += Offset(args[2], args[3]);
            path.quadraticBezierTo(currentPointControl1.dx,
                currentPointControl1.dy, currentPoint.dx, currentPoint.dy);
            break;
          case 'Z':
          case 'z':
            path.close();
            break;
        }
      }
      return path;
    });
  }

  void _drawTextOnBitmap(
    Canvas canvas,
    String imageKey,
    Rect frameRect,
    int frameAlpha,
  ) {
    final dynamicText = videoItem.dynamicItem.dynamicText;
    final textPainter = dynamicText[imageKey];
    if (textPainter == null) return;

    canvas.save();
    try {
      canvas.translate(frameRect.left, frameRect.top);
      canvas.scale(frameRect.width / textPainter.width,
          frameRect.height / textPainter.height);

      final paint = Paint()
        ..colorFilter = ColorFilter.mode(
          Color.fromARGB(frameAlpha, 255, 255, 255),
          BlendMode.modulate,
        );

      canvas.saveLayer(Offset.zero & textPainter.size, paint);
      try {
        textPainter.paint(canvas, Offset.zero);
      } finally {
        canvas.restore();
      }
    } finally {
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_SVGAPainter oldDelegate) {
    if (controller._canvasNeedsClear == true) {
      return true;
    }

    return !(oldDelegate.controller == controller &&
        oldDelegate.controller.videoItem == controller.videoItem &&
        oldDelegate.fit == fit &&
        oldDelegate.filterQuality == filterQuality &&
        oldDelegate.clipRect == clipRect);
  }
}
