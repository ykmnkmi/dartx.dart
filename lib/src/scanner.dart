import 'package:_fe_analyzer_shared/src/scanner/abstract_scanner.dart'
    show AbstractScanner, ScannerConfiguration;
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart'
    show ScannerConfiguration, Token;
import 'package:_fe_analyzer_shared/src/scanner/token_constants.dart'
    show EOF_TOKEN;
import 'package:dartx/src/string_scanner_base.dart';
import 'package:dartx/src/token.dart';
import 'package:dartx/src/x_scanner.dart';
import 'package:source_span/source_span.dart' show SourceFile;

final class DartXScanner extends AbstractScanner
    with StringScannerBase, XScanner {
  DartXScanner(this.string, {ScannerConfiguration? configuration, Uri? url})
      : sourceFile = SourceFile.fromString(string, url: url),
        scanOffset = -1,
        super(configuration, true, null);

  @override
  final SourceFile sourceFile;

  @override
  String string;

  @override
  int scanOffset;

  @override
  void appendToken(Token token) {
    if (token.kind != EOF_TOKEN) {
      token = LazyToken(token, this);
    }

    super.appendToken(token);
  }

  int scanNextToken(int next) {
    Token current = tail;

    while (identical(tail, current)) {
      if (atEndOfFile()) {
        appendEofToken();
        break;
      } else {
        next = bigSwitch(next);
      }
    }

    return next;
  }

  @override
  Token tokenize() {
    scanNextToken(advance());
    return firstToken();
  }

  void replace(int offset, int position, String html) {
    throw (offset, position, html);
  }

  void end() {
    lineStarts.add(stringOffset + 1);
  }
}
