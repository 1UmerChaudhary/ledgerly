import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:printing/printing.dart';

/// The one seam between our print logic and the operating system: sending a
/// PDF to a printer, or saving PDF/PNG bytes somewhere the user chooses.
/// Tests replace this with a fake that only records calls — real OS printing
/// and save dialogs cannot be exercised inside an automated test.
abstract class PrintingService {
  Future<void> print(Uint8List pdfBytes, {required String jobName});
  Future<bool> exportPdf(Uint8List pdfBytes, {required String suggestedName});

  /// Rasterises each page of [pdfBytes] to a 300 DPI PNG and saves it,
  /// suffixed "-1", "-2", ... when there is more than one page. Returns the
  /// number of pages actually written.
  Future<int> exportPng(
    Uint8List pdfBytes, {
    required String suggestedBaseName,
  });
}

class RealPrintingService implements PrintingService {
  @override
  Future<void> print(Uint8List pdfBytes, {required String jobName}) =>
      Printing.layoutPdf(onLayout: (_) async => pdfBytes, name: jobName);

  @override
  Future<bool> exportPdf(Uint8List pdfBytes, {required String suggestedName}) =>
      Printing.sharePdf(bytes: pdfBytes, filename: suggestedName);

  @override
  Future<int> exportPng(
    Uint8List pdfBytes, {
    required String suggestedBaseName,
  }) async {
    final pages = await Printing.raster(pdfBytes, dpi: 300).toList();
    var written = 0;
    for (var i = 0; i < pages.length; i++) {
      final png = await pages[i].toPng();
      final suggested = pages.length == 1
          ? '$suggestedBaseName.png'
          : '$suggestedBaseName-${i + 1}.png';
      final location = await getSaveLocation(
        suggestedName: suggested,
        acceptedTypeGroups: const [
          XTypeGroup(label: 'PNG image', extensions: ['png']),
        ],
      );
      if (location == null) break; // user cancelled — stop, don't ask again
      await File(location.path).writeAsBytes(png);
      written++;
    }
    return written;
  }
}
