import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:barcode/barcode.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

const _padding = 24.0;

Future<Uint8List> generateBarcodePng(String data, {String? label, double width = 500, double barcodeHeight = 160}) async {
  final bc = Barcode.code128();
  final innerW = width - _padding * 2;
  final elements = bc.make(data, width: innerW, height: barcodeHeight);
  final labelH = label != null ? 36.0 : 0.0;
  final totalH = barcodeHeight + labelH + _padding * 2;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, totalH));
  canvas.clipRect(Rect.fromLTWH(0, 0, width, totalH));
  canvas.drawColor(Colors.white, BlendMode.src);
  canvas.save();
  canvas.translate(_padding, _padding);
  for (final el in elements) {
    if (el is BarcodeBar) {
      final paint = Paint()..color = el.black ? Colors.black : Colors.white;
      canvas.drawRect(Rect.fromLTWH(el.left, el.top, el.width, el.height), paint);
    }
  }
  canvas.restore();
  if (label != null) {
    final ts = ui.TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500);
    final ps = ui.ParagraphStyle(textAlign: TextAlign.center, maxLines: 3);
    final pb = ui.ParagraphBuilder(ps)..pushStyle(ts)..addText(label);
    final p = pb.build()..layout(ui.ParagraphConstraints(width: innerW));
    canvas.save();
    canvas.translate(_padding, _padding + barcodeHeight + 6);
    canvas.drawParagraph(p, Offset.zero);
    canvas.restore();
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(width.toInt(), totalH.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

Future<File> saveBarcodeImage(String data, String fileName, {String? label}) async {
  final png = await generateBarcodePng(data, label: label);
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName.png');
  await file.writeAsBytes(png);
  return file;
}

Future<void> shareBarcodeImage(String data, String productName, String category) async {
  final label = productName.length > 28 ? productName : '$productName  |  $category';
  final file = await saveBarcodeImage(data, 'barcode_$productName', label: label);
  await Share.shareXFiles([XFile(file.path)], text: 'Штрих-код: $productName');
}

Future<void> shareAllBarcodes(List<Map<String, dynamic>> products) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/all_barcodes.html');
  final buf = StringBuffer();

  buf.writeln('<!DOCTYPE html><html lang="ru"><head><meta charset="UTF-8">');
  buf.writeln('<style>');
  buf.writeln('* { margin: 0; padding: 0; box-sizing: border-box; }');
  buf.writeln('body { font-family: Arial, sans-serif; padding: 20px; }');
  buf.writeln('h1 { font-size: 18px; margin-bottom: 16px; color: #333; }');
  buf.writeln('.grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }');
  buf.writeln('.item { border: 1px solid #ddd; border-radius: 6px; padding: 10px; text-align: center; page-break-inside: avoid; }');
  buf.writeln('.item img { max-width: 100%; height: auto; }');
  buf.writeln('.item .label { font-size: 13px; color: #333; margin-top: 6px; font-weight: 600; }');
  buf.writeln('.item .code { font-size: 12px; color: #777; }');
  buf.writeln('@media print { body { padding: 10px; } .item { border: 1px solid #ccc; } }');
  buf.writeln('</style></head><body>');
  buf.writeln('<h1>Штрих-коды товаров (${products.length} шт.)</h1>');
  buf.writeln('<div class="grid">');

  for (final p in products) {
    final bc = p['barcode'] as String?;
    final name = p['name'] as String? ?? '';
    final cat = p['category'] as String? ?? '';
    if (bc == null || bc.isEmpty) continue;
    final label = name.length > 25 ? name : '$name  |  $cat';
    final pngBytes = await generateBarcodePng(bc, label: label, width: 400);
    final b64 = base64Encode(pngBytes);
    buf.writeln('<div class="item">');
    buf.writeln('<img src="data:image/png;base64,$b64" alt="$name" />');
    buf.writeln('<div class="label">$name</div>');
    if (cat.isNotEmpty) { buf.writeln('<div class="code">$cat  |  $bc</div>'); }
    else { buf.writeln('<div class="code">$bc</div>'); }
    buf.writeln('</div>');
  }

  buf.writeln('</div></body></html>');
  await file.writeAsString(buf.toString());
  await Share.shareXFiles([XFile(file.path)], text: 'Все штрих-коды');
}
