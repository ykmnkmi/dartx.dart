import 'package:_fe_analyzer_shared/src/parser/identifier_context.dart'
    show IdentifierContext;
import 'package:_fe_analyzer_shared/src/parser/parser_impl.dart' as fe
    show ConstantPatternContext, Parser;
import 'package:_fe_analyzer_shared/src/parser/type_info.dart'
    show TypeInfo, TypeParamOrArgInfo, computeType, computeTypeParamOrArg;
import 'package:_fe_analyzer_shared/src/parser/util.dart' show optional;
import 'package:_fe_analyzer_shared/src/scanner/token.dart'
    show BeginToken, Token, TokenType;
import 'package:_fe_analyzer_shared/src/scanner/token_constants.dart'
    show
        FUNCTION_TOKEN,
        IDENTIFIER_TOKEN,
        KEYWORD_TOKEN,
        OPEN_CURLY_BRACKET_TOKEN;
import 'package:_fe_analyzer_shared/src/util/link.dart' show Link;
import 'package:analyzer/dart/ast/ast.dart' show CompilationUnit;
import 'package:analyzer/src/fasta/ast_builder.dart' show AstBuilder;
import 'package:dart_style/dart_style.dart' show DartFormatter;
import 'package:dartx/src/scanner.dart';
import 'package:dartx/src/x_parser.dart';

final class DartXParser extends fe.Parser with XParser {
  DartXParser(
    super.listener, {
    super.allowPatterns,
    required this.scanner,
  });

  @override
  final DartXScanner scanner;

  @override
  AstBuilder get builder {
    return listener as AstBuilder;
  }

  @override
  void push(Object object) {
    builder.push(object);
  }

  @override
  Object? pop() {
    return builder.pop();
  }

  @override
  bool looksLikeFunctionBody(Token token) {
    int currentOffset = scanner.scanOffset;
    Link<BeginToken> currentStack = scanner.groupingStack;
    Token tail = scanner.tail;

    scanner.groupingStack = const Link<BeginToken>();
    scanner.scanOffset = token.offset - 1;

    int char = scanner.advance();

    while (!scanner.atEndOfFile()) {
      char = scanner.scanNextToken(char);

      if (scanner.groupingStack.isEmpty) {
        break;
      }
    }

    scanner.tail.previous = null;
    tail.next = null;
    scanner.tail = tail;
    scanner.groupingStack = currentStack;
    scanner.scanOffset = currentOffset;

    Token next = scanner.tail.next!;
    return optional('{', next) ||
        optional('=>', next) ||
        optional('async', next) ||
        optional('sync', next);
  }

  String parse() {
    Token token = scanner.tokenize();
    parseUnit(token);

    Object? unit = builder.pop();

    if (unit is! CompilationUnit) {
      throw StateError('Expected CompilationUnit, got $unit');
    }

    DartFormatter formatter = DartFormatter();
    return formatter.format('$unit');
  }

  @override
  Token parseExpression(Token token) {
    Token? next = token.next;

    if (next != null && next.type == TokenType.LT && next.offset >= parsed) {
      return parseNode(next);
    }

    return super.parseExpression(token);
  }

  @override
  Token parseParenthesizedExpressionFunctionLiteralOrRecordLiteral(
    Token token,
    fe.ConstantPatternContext constantPatternContext,
  ) {
    Token next = token.next!;
    assert(optional('(', next));

    if (mayParseFunctionExpressions) {
      Token nextToken = next.endGroup!.next!;
      int kind = nextToken.kind;

      if (kind case FUNCTION_TOKEN || OPEN_CURLY_BRACKET_TOKEN) {
        listener.handleNoTypeVariables(next);
        return parseFunctionExpression(token);
      }

      if (kind case KEYWORD_TOKEN || IDENTIFIER_TOKEN) {
        if (optional('async', nextToken) || optional('sync', nextToken)) {
          listener.handleNoTypeVariables(next);
          return parseFunctionExpression(token);
        }

        // Recovery
        // If there is a stray simple identifier in the function expression
        // because the user is typing (e.g. `() asy {}`) then continue parsing
        // and allow parseFunctionExpression to report an unexpected token.
        kind = nextToken.next!.kind;

        if (kind case FUNCTION_TOKEN || OPEN_CURLY_BRACKET_TOKEN) {
          listener.handleNoTypeVariables(next);
          return parseFunctionExpression(token);
        }
      }
    }

    bool old = mayParseFunctionExpressions;
    mayParseFunctionExpressions = true;

    token = parseParenthesizedExpressionOrRecordLiteral(
      token,
      null,
      constantPatternContext,
    );

    mayParseFunctionExpressions = old;
    return token;
  }

  @override
  Token parseSendOrFunctionLiteral(
    Token token,
    IdentifierContext context,
    fe.ConstantPatternContext constantPatternContext,
  ) {
    if (!mayParseFunctionExpressions) {
      return parseSend(token, context, constantPatternContext);
    }

    TypeInfo typeInfo = computeType(token, false);
    Token beforeName = typeInfo.skipType(token);
    Token name = beforeName.next!;

    if (name.isIdentifier) {
      TypeParamOrArgInfo typeParam = computeTypeParamOrArg(name);
      Token skipped = typeParam.skip(name);
      Token next = skipped.next!;

      if (optional('(', next) && looksLikeFunctionBody(next)) {
        return parseFunctionLiteral(
          token,
          beforeName,
          name,
          typeInfo,
          typeParam,
          context,
        );
      }
    }

    return parseSend(token, context, constantPatternContext);
  }
}
