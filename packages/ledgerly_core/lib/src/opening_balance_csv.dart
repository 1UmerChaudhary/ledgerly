import 'money.dart';

/// A row parsed from an opening-balances CSV or grid: a name, an optional
/// phone, and a signed starting balance (+ receivable, − giveable).
class OpeningBalanceRow {
  const OpeningBalanceRow({
    required this.name,
    required this.phone,
    required this.balance,
  });

  final String name;
  final String? phone;
  final Money balance;
}

class OpeningBalanceParseError {
  const OpeningBalanceParseError(this.line, this.message);
  final int line;
  final String message;
}

class ParsedOpeningBalances {
  const ParsedOpeningBalances(this.rows, this.errors);
  final List<OpeningBalanceRow> rows;
  final List<OpeningBalanceParseError> errors;
}

/// Parses "name,phone,balance" lines (a header row, if present, is skipped;
/// blank lines are ignored). One bad line never loses the good ones — it is
/// reported with its 1-based line number instead. Balance accepts anything
/// [parseMoney] does ("1,25,000", "-500", quoted or not), so a bookkeeper
/// pasting from a spreadsheet doesn't have to reformat numbers by hand.
ParsedOpeningBalances parseOpeningBalancesCsv(String content) {
  final rows = <OpeningBalanceRow>[];
  final errors = <OpeningBalanceParseError>[];
  final lines = content.split(RegExp(r'\r\n|\r|\n'));

  for (var i = 0; i < lines.length; i++) {
    final lineNo = i + 1;
    final raw = lines[i].trim();
    if (raw.isEmpty) continue;
    final cells = _splitCsvLine(raw);
    if (i == 0 && cells.isNotEmpty && cells[0].toLowerCase() == 'name') {
      continue; // header row
    }
    if (cells.length != 3) {
      errors.add(
        OpeningBalanceParseError(
          lineNo,
          'Expected 3 columns (name,phone,balance), got ${cells.length}.',
        ),
      );
      continue;
    }
    final name = cells[0].trim();
    if (name.isEmpty) {
      errors.add(OpeningBalanceParseError(lineNo, 'A name is required.'));
      continue;
    }
    final balance = parseMoney(cells[2].trim());
    if (balance == null) {
      errors.add(
        OpeningBalanceParseError(lineNo, 'Could not read the balance amount.'),
      );
      continue;
    }
    final phone = cells[1].trim();
    rows.add(
      OpeningBalanceRow(
        name: name,
        phone: phone.isEmpty ? null : phone,
        balance: balance,
      ),
    );
  }
  return ParsedOpeningBalances(rows, errors);
}

/// Splits one CSV line into cells, honouring quotes so a comma inside a
/// quoted field ("6,20,000") is not treated as a column separator. `""`
/// inside a quoted field is an escaped literal quote.
List<String> _splitCsvLine(String line) {
  final cells = <String>[];
  final buffer = StringBuffer();
  var inQuotes = false;
  for (var i = 0; i < line.length; i++) {
    final ch = line[i];
    if (inQuotes) {
      if (ch == '"') {
        if (i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        buffer.write(ch);
      }
    } else if (ch == '"') {
      inQuotes = true;
    } else if (ch == ',') {
      cells.add(buffer.toString().trim());
      buffer.clear();
    } else {
      buffer.write(ch);
    }
  }
  cells.add(buffer.toString().trim());
  return cells;
}
