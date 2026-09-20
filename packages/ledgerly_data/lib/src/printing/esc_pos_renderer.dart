import 'dart:convert';
import 'dart:typed_data';

import 'package:ledgerly_core/ledgerly_core.dart';

import 'print_models.dart';

// Standard ESC/POS control bytes used by essentially every 58/80mm thermal
// printer's command set (Epson's original spec, near-universally cloned).
const List<int> _init = [0x1B, 0x40]; // ESC @
const List<int> _boldOn = [0x1B, 0x45, 0x01]; // ESC E 1
const List<int> _boldOff = [0x1B, 0x45, 0x00]; // ESC E 0
const List<int> _centerOn = [0x1B, 0x61, 0x01]; // ESC a 1
const List<int> _leftAlign = [0x1B, 0x61, 0x00]; // ESC a 0
const List<int> _fullCut = [0x1D, 0x56, 0x00, 0x00]; // GS V 0 0

List<int> _line(String text) => [...utf8.encode(text), 0x0A];

/// The Bluetooth-thermal-printer equivalent of [buildSlipPdf]: same
/// [SlipModel] input, raw ESC/POS bytes instead of a PDF page. Synchronous
/// -- unlike the PDF path, there is no underlying async rendering library
/// involved in building a plain byte stream.
Uint8List buildSlipEscPos(SlipModel s) {
  final bytes = <int>[..._init, ..._centerOn, ..._boldOn];
  bytes.addAll(_line(s.firmName));
  bytes.addAll([..._boldOff, ..._leftAlign]);
  bytes.addAll(_line(s.firmContact));
  if (s.firmAddress case final address?) bytes.addAll(_line(address));
  bytes.addAll(_line('Slip ${s.displayNo}  ${s.entryDate}'));
  bytes.addAll(_line(s.customerName ?? 'Cash Sale'));
  bytes.addAll(_line('-' * 32));
  for (final line in s.lines) {
    bytes.addAll(_line(line.itemName));
    bytes.addAll(
      _line('${line.quantityDescription}  ${line.rateDescription}  ${formatMoney(line.amount)}'),
    );
  }
  bytes.addAll(_line('-' * 32));
  bytes.addAll([..._boldOn]);
  bytes.addAll(_line('Total: ${formatMoney(s.total)}'));
  bytes.addAll([..._boldOff]);
  if (s.previousBalance != null && s.newBalance != null) {
    bytes.addAll(_line('Previous balance: ${formatMoney(s.previousBalance!)}'));
    bytes.addAll(_line('New balance: ${formatMoney(s.newBalance!)}'));
  }
  if (s.edited) bytes.addAll(_line('(edited)'));
  bytes.addAll(_line('Device ${s.deviceCode}'));
  bytes.addAll([0x0A, 0x0A]);
  bytes.addAll(_fullCut);
  return Uint8List.fromList(bytes);
}
