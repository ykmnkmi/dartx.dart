import 'package:_fe_analyzer_shared/src/scanner/token.dart'
    show CommentToken, Keyword, Token, TokenType;
import 'package:dartx/src/scanner.dart';

final class LazyToken implements Token {
  LazyToken(this.token, this.scanner);

  final Token token;

  final DartXScanner scanner;

  @override
  int get charCount {
    return token.charCount;
  }

  @override
  int get charEnd {
    return token.charEnd;
  }

  @override
  int get charOffset {
    return token.charOffset;
  }

  @override
  Token? get beforeSynthetic {
    return token.beforeSynthetic;
  }

  @override
  set beforeSynthetic(Token? value) {
    token.beforeSynthetic = value;
  }

  @override
  int get end {
    return token.end;
  }

  @override
  Token? get endGroup {
    return null;
  }

  @override
  bool get isEof {
    return token.isEof;
  }

  @override
  bool get isIdentifier {
    return token.isIdentifier;
  }

  @override
  bool get isKeyword {
    return token.isKeyword;
  }

  @override
  bool get isKeywordOrIdentifier {
    return token.isKeywordOrIdentifier;
  }

  @override
  bool get isModifier {
    return token.isModifier;
  }

  @override
  bool get isOperator {
    return token.isOperator;
  }

  @override
  bool get isSynthetic {
    return token.isSynthetic;
  }

  @override
  bool get isTopLevelKeyword {
    return token.isTopLevelKeyword;
  }

  @override
  bool get isUserDefinableOperator {
    return token.isUserDefinableOperator;
  }

  @override
  Keyword? get keyword {
    return token.keyword;
  }

  @override
  int get kind {
    return token.kind;
  }

  @override
  int get length {
    return token.length;
  }

  @override
  String get lexeme {
    return token.lexeme;
  }

  @override
  Token? get next {
    if (token.next == null) {
      assert(token.offset == scanner.tail.offset);

      int code = scanner.string.codeUnitAt(token.end);
      scanner.scanNextToken(code);
    }

    return token.next;
  }

  @override
  set next(Token? next) {
    token.next = next;
  }

  @override
  int get offset {
    return token.offset;
  }

  @override
  set offset(int value) {
    token.offset = value;
  }

  @override
  CommentToken? get precedingComments {
    return token.precedingComments;
  }

  @override
  Token? get previous {
    return token.previous;
  }

  @override
  set previous(Token? value) {
    token.previous = value;
  }

  @override
  String? get stringValue {
    return token.stringValue;
  }

  @override
  TokenType get type {
    return token.type;
  }

  @override
  int get hashCode {
    return token.hashCode;
  }

  @override
  bool operator ==(Object other) {
    return other is LazyToken && token == other.token || token == other;
  }

  @override
  bool matchesAny(List<TokenType> types) {
    return token.matchesAny(types);
  }

  @override
  Token setNext(Token token) {
    return this.token.setNext(token);
  }

  @override
  Token? setNextWithoutSettingPrevious(Token? token) {
    return this.token.setNextWithoutSettingPrevious(token);
  }

  @override
  String toString() {
    return token.toString();
  }

  @override
  Object value() {
    return token.value();
  }
}

String stack() {
  return StackTrace.current.toString().split('\n').elementAt(2).substring(8);
}
