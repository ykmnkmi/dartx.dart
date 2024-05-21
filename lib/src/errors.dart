import 'package:source_span/source_span.dart';

class ParseError extends Error {
  ParseError(this.errorCode, this.span);

  final ErrorCode errorCode;

  final SourceSpan span;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'code': errorCode.code,
      'message': errorCode.message,
      'line': span.start.line + 1,
      'column': span.start.column,
      'offset': span.start.offset,
    };
  }

  @override
  String toString() {
    return 'ParseError: ${errorCode.message}';
  }
}

typedef ErrorCode = ({String code, String message});

const ErrorCode expectedFragment = (
  code: 'expected-fragment',
  message: 'Expected fragment',
);

const ErrorCode expectedProperty = (
  code: 'expected-property',
  message: 'Expected property',
);

const ErrorCode expectedTag = (
  code: 'expected-tag',
  message: 'Expected tag',
);

const ErrorCode invalidTagName = (
  code: 'invalid-tag-name',
  message: 'Expected valid tag name',
);

const ErrorCode capitalTagName = (
  code: 'capital-tag-name',
  message: 'Expected lowercase tag name',
);

const ErrorCode missingAttributeValue = (
  code: 'missing-attribute-value',
  message: 'Expected value for the attribute',
);

ErrorCode unclosedAttributeValue(String token) {
  return (
    code: 'unclosed-attribute-value',
    message: 'Expected to close the attribute value with $token',
  );
}

const ErrorCode unexpectedEOF = (
  code: 'unexpected-eof',
  message: 'Unexpected end of input',
);

ErrorCode unexpectedEOFToken(Pattern token) {
  return (
    code: 'unexpected-eof',
    message: 'Unexpected $token',
  );
}

ErrorCode unexpectedToken(Pattern token) {
  return (
    code: 'unexpected-token',
    message: 'Expected $token',
  );
}
