import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:printing/printing.dart';

import '../bootstrap/global_prefs.dart';

/// A printer as far as this app cares: enough to find it again.
class PrinterInfo {
  const PrinterInfo({required this.name, required this.url});
  final String name;
  final String url;
}

/// Lists the printers this machine knows about. A separate seam from
/// [PrintingService] because listing is read-only and needed just for the
/// Settings picker, while [PrintingService] is the one that actually prints.
abstract class PrinterDiscovery {
  Future<List<PrinterInfo>> list();
}

class RealPrinterDiscovery implements PrinterDiscovery {
  @override
  Future<List<PrinterInfo>> list() async {
    final printers = await Printing.listPrinters();
    return [for (final p in printers) PrinterInfo(name: p.name, url: p.url)];
  }
}

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
  RealPrintingService(this.prefs);
  final GlobalPrefs prefs;

  /// Silent to the saved default printer once one is chosen in Settings; a
  /// print dialog every time until then. Matches every other choice in this
  /// app that degrades to "ask" rather than fail when nothing is configured.
  @override
  Future<void> print(Uint8List pdfBytes, {required String jobName}) async {
    final name = prefs.printerName;
    final url = prefs.printerUrl;
    if (name != null && url != null) {
      await Printing.directPrintPdf(
        printer: Printer(url: url, name: name),
        onLayout: (_) async => pdfBytes,
        name: jobName,
      );
      return;
    }
    await Printing.layoutPdf(onLayout: (_) async => pdfBytes, name: jobName);
  }

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
