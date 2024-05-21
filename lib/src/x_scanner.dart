import 'package:dartx/src/errors.dart';
import 'package:dartx/src/patterns.dart';
import 'package:dartx/src/string_scanner_base.dart';
import 'package:source_span/source_span.dart';

mixin XScanner on StringScannerBase {
  SourceFile get sourceFile;

  void allowSpace({bool required = false}) {
    int start = scanOffset;

    Match? match = spaceRe.matchAsPrefix(string, scanOffset);

    if (match != null) {
      scanOffset = match.end;
    }

    if (required && start == scanOffset) {
      error((code: 'missing-whitespace', message: 'Expected whitespace'));
    }
  }

  void skip(Pattern pattern) {
    Match? match = pattern.matchAsPrefix(string, scanOffset);

    if (match != null) {
      scanOffset = match.end;
    }
  }

  bool match(Pattern pattern) {
    return pattern.matchAsPrefix(string, scanOffset) != null;
  }

  bool scan(Pattern pattern) {
    Match? match = pattern.matchAsPrefix(string, scanOffset);

    if (match != null) {
      scanOffset = match.end;
      return true;
    }

    return false;
  }

  String? read(Pattern pattern) {
    Match? match = pattern.matchAsPrefix(string, scanOffset);

    if (match != null) {
      scanOffset = match.end;
      return match[0];
    }

    return null;
  }

  String readUntil(Pattern pattern, [ErrorCode? errorCode]) {
    int found = string.indexOf(pattern, scanOffset);

    if (found != -1) {
      return string.substring(scanOffset, scanOffset = found);
    }

    if (atEndOfFile()) {
      if (errorCode != null) {
        error(errorCode);
      }

      error(unexpectedEOF);
    }

    return string.substring(scanOffset, scanOffset = string.length);
  }

  void expect(Pattern pattern, [ErrorCode? errorCode]) {
    Match? match = pattern.matchAsPrefix(string, scanOffset);

    if (match != null) {
      scanOffset = match.end;
      return;
    }

    if (errorCode != null) {
      error(errorCode, scanOffset);
    }

    if (atEndOfFile()) {
      error(unexpectedEOFToken(pattern));
    }

    error(unexpectedToken(pattern), scanOffset);
  }

  Never dartError(String message, int offset, int length) {
    error(
      (code: 'parse-error', message: message),
      offset,
      offset + length,
    );
  }

  Never error(ErrorCode errorCode, [int? position, int? end]) {
    position ??= scanOffset;
    end ??= position;

    SourceSpan span = sourceFile.span(position, end);
    throw ParseError(errorCode, span);
  }
}
