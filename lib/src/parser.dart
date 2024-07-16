import 'package:_fe_analyzer_shared/src/messages/codes.dart' as codes;
import 'package:_fe_analyzer_shared/src/parser/async_modifier.dart'
    show AsyncModifier;
import 'package:_fe_analyzer_shared/src/parser/block_kind.dart' show BlockKind;
import 'package:_fe_analyzer_shared/src/parser/identifier_context.dart'
    show IdentifierContext;
import 'package:_fe_analyzer_shared/src/parser/modifier_context.dart'
    show isModifier;
import 'package:_fe_analyzer_shared/src/parser/parser_impl.dart' as fe
    show AwaitOrYieldContext, ConstantPatternContext, Parser, PatternContext;
import 'package:_fe_analyzer_shared/src/parser/type_info.dart'
    show TypeInfo, TypeParamOrArgInfo, computeType, computeTypeParamOrArg;
import 'package:_fe_analyzer_shared/src/parser/util.dart' show optional;
import 'package:_fe_analyzer_shared/src/scanner/token.dart'
    show Token, TokenType;
import 'package:_fe_analyzer_shared/src/scanner/token_constants.dart'
    show
        FUNCTION_TOKEN,
        IDENTIFIER_TOKEN,
        KEYWORD_TOKEN,
        OPEN_CURLY_BRACKET_TOKEN;
import 'package:analyzer/dart/ast/ast.dart' show CompilationUnit;
import 'package:analyzer/error/error.dart';
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

  String parse() {
    Token token = scanner.tokenize();

    try {
      parseUnit(token);
    } on AnalysisError catch (error) {
      scanner.dartError(error.message, error.offset, error.length);
    }

    Object? unit = builder.pop();

    if (unit is! CompilationUnit) {
      throw StateError('Expected CompilationUnit, got $unit');
    }

    DartFormatter formatter = DartFormatter();
    return formatter.format(scanner.string);
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
  Token parseExpressionInParenthesisRest(
    Token token, {
    required bool allowCase,
  }) {
    assert(optional('(', token));

    Token begin = token; // BeginToken begin = token as BeginToken;
    token = parseExpression(token);

    Token next = token.next!;

    if (allowPatterns && optional('case', next)) {
      Token case_ = token = next;
      token = parsePattern(token, fe.PatternContext.matching);
      next = token.next!;

      Token? when;

      if (optional('when', next)) {
        when = token = next;
        listener.beginPatternGuard(when);
        token = parseExpression(token);
        listener.endPatternGuard(when);
      }

      token = ensureCloseParen(token, begin);
      listener.handleParenthesizedCondition(begin, case_, when);
    } else {
      token = ensureCloseParen(token, begin);
      listener.handleParenthesizedCondition(begin, null, null);
    }

    assert(optional(')', token));
    return token;
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

  @override
  Token parseStatementX(Token token) {
    if (identical(token.next!.kind, IDENTIFIER_TOKEN)) {
      if (optional(':', token.next!.next!)) {
        return parseLabeledStatement(token);
      }

      return parseExpressionStatementOrDeclarationAfterModifiers(
        token,
        token,
        null,
        null,
        null,
      );
    }

    String? value = token.next!.stringValue;

    if (identical(value, '{')) {
      // The scanner ensures that `{` always has a closing `}`.
      if (allowPatterns) {
        Token next = token.next!;

        if (optional('=', next.endGroup!.next!)) {
          // Expression statement beginning with a pattern assignment
          return parseExpressionStatement(token);
        }
      }

      return parseBlock(token, BlockKind.statement);
    }

    if (identical(value, 'return')) {
      return parseReturnStatement(token);
    }

    if (identical(value, 'var') || identical(value, 'final')) {
      Token varOrFinal = token.next!;

      if (!isModifier(varOrFinal.next!)) {
        return parseExpressionStatementOrDeclarationAfterModifiers(
          varOrFinal,
          token,
          null,
          varOrFinal,
          null,
        );
      }

      return parseExpressionStatementOrDeclaration(token);
    }

    if (identical(value, 'if')) {
      return parseIfStatement(token);
    }

    if (identical(value, 'await') && optional('for', token.next!.next!)) {
      return parseForStatement(token.next!, token.next!);
    }

    if (identical(value, 'for')) {
      return parseForStatement(token, /* awaitToken = */ null);
    }

    if (identical(value, 'rethrow')) {
      return parseRethrowStatement(token);
    }

    if (identical(value, 'while')) {
      return parseWhileStatement(token);
    }

    if (identical(value, 'do')) {
      return parseDoWhileStatement(token);
    }

    if (identical(value, 'try')) {
      return parseTryStatement(token);
    }

    if (identical(value, 'switch')) {
      return parseSwitchStatement(token);
    }

    if (identical(value, 'break')) {
      return parseBreakStatement(token);
    }

    if (identical(value, 'continue')) {
      return parseContinueStatement(token);
    }

    if (identical(value, 'assert')) {
      return parseAssertStatement(token);
    }

    if (identical(value, ';')) {
      return parseEmptyStatement(token);
    }

    if (identical(value, 'yield')) {
      switch (asyncState) {
        case AsyncModifier.Sync:
          if (optional(':', token.next!.next!)) {
            return parseLabeledStatement(token);
          }

          if (looksLikeYieldStatement(
              token, fe.AwaitOrYieldContext.Statement)) {
            // Recovery: looks like an expression preceded by `yield` but not
            // inside an Async or AsyncStar context. parseYieldStatement will
            // report the error.
            return parseYieldStatement(token);
          }

          return parseExpressionStatementOrDeclaration(token);

        case AsyncModifier.SyncStar || AsyncModifier.AsyncStar:
          return parseYieldStatement(token);

        case AsyncModifier.Async:
          return parseYieldStatement(token);
      }
    }

    if (identical(value, 'const')) {
      return parseExpressionStatementOrConstDeclaration(token);
    }

    if (identical(value, 'await')) {
      if (inPlainSync) {
        if (!looksLikeAwaitExpression(
            token, fe.AwaitOrYieldContext.Statement)) {
          return parseExpressionStatementOrDeclaration(token);
        }

        // Recovery: looks like an expression preceded by `await`
        // but not inside an async context.
        // Fall through to parseExpressionStatement
        // and parseAwaitExpression will report the error.
      }

      return parseExpressionStatement(token);
    }

    if (identical(value, 'set') && token.next!.next!.isIdentifier) {
      // Recovery: invalid use of `set`
      reportRecoverableErrorWithToken(
        token.next!,
        codes.templateUnexpectedToken,
      );

      return parseStatementX(token.next!);
    }

    if (token.next!.isIdentifier) {
      if (optional(':', token.next!.next!)) {
        return parseLabeledStatement(token);
      }

      return parseExpressionStatementOrDeclaration(token);
    }

    return parseExpressionStatementOrDeclaration(token);
  }
}
