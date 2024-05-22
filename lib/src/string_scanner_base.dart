import 'package:_fe_analyzer_shared/src/scanner/abstract_scanner.dart'
    show AbstractScanner;
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart'
    show LanguageVersionToken, StringTokenImpl;
import 'package:_fe_analyzer_shared/src/scanner/string_canonicalizer.dart'
    show canonicalizeString, canonicalizeSubString;
import 'package:_fe_analyzer_shared/src/scanner/token.dart'
    show
        CommentToken,
        LanguageVersionToken,
        StringToken,
        SyntheticStringToken,
        TokenType;
import 'package:_fe_analyzer_shared/src/scanner/token_impl.dart'
    show DartDocToken, LanguageVersionTokenImpl, StringTokenImpl;

mixin StringScannerBase on AbstractScanner {
  abstract String string;

  @override
  abstract int scanOffset;

  @override
  int get stringOffset {
    return scanOffset;
  }

  @override
  int advance() {
    return string.codeUnitAt(++scanOffset);
  }

  @override
  int peek() {
    return string.codeUnitAt(scanOffset + 1);
  }

  @override
  bool atEndOfFile() {
    return scanOffset >= string.length - 1;
  }

  @override
  int currentAsUnicode(int next) {
    return next;
  }

  @override
  void handleUnicode(int startScanOffset) {}

  @override
  StringToken createSubstringToken(
    TokenType type,
    int start,
    bool asciiOnly, [
    int extraOffset = 0,
  ]) {
    return StringTokenImpl.fromString(
      type,
      string.substring(start, scanOffset + extraOffset),
      tokenStart,
      canonicalize: true,
      precedingComments: comments,
    );
  }

  @override
  StringToken createSyntheticSubstringToken(
    TokenType type,
    int start,
    bool asciiOnly,
    String syntheticChars,
  ) {
    String value = syntheticChars.isEmpty
        ? canonicalizeSubString(string, start, scanOffset)
        : canonicalizeString(
            string.substring(start, scanOffset) + syntheticChars);
    return SyntheticStringToken(
      type,
      value,
      tokenStart,
      value.length - syntheticChars.length,
    );
  }

  @override
  CommentToken createCommentToken(
    TokenType type,
    int start,
    bool asciiOnly, [
    int extraOffset = 0,
  ]) {
    // return CommentTokenImpl.fromSubstring(
    //   type,
    //   string,
    //   start,
    //   scanOffset + extraOffset,
    //   tokenStart,
    //   canonicalize: true,
    // );
    throw UnimplementedError();
  }

  @override
  DartDocToken createDartDocToken(
    TokenType type,
    int start,
    bool asciiOnly, [
    int extraOffset = 0,
  ]) {
    // return DartDocToken.fromSubstring(
    //   type,
    //   string,
    //   start,
    //   scanOffset + extraOffset,
    //   tokenStart,
    //   canonicalize: true,
    // );
    throw UnimplementedError();
  }

  @override
  LanguageVersionToken createLanguageVersionToken(
    int start,
    int major,
    int minor,
  ) {
    return LanguageVersionTokenImpl.fromSubstring(
      string,
      start,
      scanOffset,
      tokenStart,
      major,
      minor,
      canonicalize: true,
    );
  }

  @override
  AbstractScanner createRecoveryOptionScanner() {
    throw UnimplementedError();
  }
}
