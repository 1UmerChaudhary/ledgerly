import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class BluetoothPrinterInfo {
  const BluetoothPrinterInfo({required this.name, required this.mac});
  final String name;
  final String mac;
}

/// The Bluetooth-transport equivalent of [PrintingService]: sends already-
/// rendered bytes ([buildSlipEscPos]'s output) to a paired thermal printer.
/// Real Bluetooth I/O cannot run inside an automated test, exactly like the
/// OS printer dialog it sits alongside -- see [FakeThermalPrinterService].
abstract class ThermalPrinterService {
  Future<List<BluetoothPrinterInfo>> pairedPrinters();
  Future<bool> connect(String mac);
  Future<bool> writeBytes(Uint8List bytes);
  Future<void> disconnect();
}

class RealThermalPrinterService implements ThermalPrinterService {
  @override
  Future<List<BluetoothPrinterInfo>> pairedPrinters() async {
    final paired = await PrintBluetoothThermal.pairedBluetooths;
    return [
      for (final p in paired)
        BluetoothPrinterInfo(name: p.name, mac: p.macAdress),
    ];
  }

  @override
  Future<bool> connect(String mac) =>
      PrintBluetoothThermal.connect(macPrinterAddress: mac);

  @override
  Future<bool> writeBytes(Uint8List bytes) =>
      PrintBluetoothThermal.writeBytes(bytes);

  @override
  Future<void> disconnect() async {
    await PrintBluetoothThermal.disconnect;
  }
}
