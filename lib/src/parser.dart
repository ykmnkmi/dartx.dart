import 'package:_fe_analyzer_shared/src/parser/identifier_context.dart';
import 'package:_fe_analyzer_shared/src/parser/parser_impl.dart' as fe;
import 'package:_fe_analyzer_shared/src/parser/type_info.dart';
import 'package:_fe_analyzer_shared/src/parser/util.dart';
import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:_fe_analyzer_shared/src/util/link.dart';
import 'package:analyzer/src/fasta/ast_builder.dart';
import 'package:dartx/src/scanner.dart';
import 'package:dartx/src/x_parser.dart';

final class DartXParser extends fe.Parser with XParser {
  DartXParser(
    AstBuilder super.listener, {
    super.allowPatterns,
    required this.scanner,
  });

  @override
  final DartXScanner scanner;

  @override
  AstBuilder get listener {
    return super.listener as AstBuilder;
  }

  @override
  void push(Object object) {
    listener.push(object);
  }

  @override
  Object? pop() {
    return listener.pop();
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

  @override
  Token parseExpression(Token token) {
    Token? next = token.next;

    if (next != null && next.type == TokenType.LT && next.offset >= parsed) {
      return parseNode(next);
    } else {
      return super.parseExpression(token);
    }
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
      Token next = typeParam.skip(name).next!;

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
