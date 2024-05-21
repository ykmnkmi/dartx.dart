import 'package:_fe_analyzer_shared/src/scanner/scanner.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/fasta/ast_builder.dart';
import 'package:analyzer/src/string_source.dart';
import 'package:dart_style/dart_style.dart';
import 'package:dartx/src/parser.dart';
import 'package:dartx/src/scanner.dart';
import 'package:dartx/src/throwing_error_listener.dart';

String convert(String string, {Uri? url}) {
  FeatureSet featureSet = FeatureSet.latestLanguageVersion();

  ScannerConfiguration configuration = ScannerConfiguration(
    enableExtensionMethods: featureSet.isEnabled(Feature.extension_methods),
    enableNonNullable: featureSet.isEnabled(Feature.non_nullable),
    enableTripleShift: featureSet.isEnabled(Feature.triple_shift),
    forAugmentationLibrary: featureSet.isEnabled(Feature.macros),
  );

  DartXScanner scanner = DartXScanner(
    string,
    configuration: configuration,
    url: url,
  );

  ThrowingErrorListener errorListener = ThrowingErrorListener();
  StringSource source = StringSource(string, null, uri: url);

  ErrorReporter reporter = ErrorReporter(
    errorListener,
    source,
    isNonNullableByDefault: true,
  );

  LineInfo lineInfo = LineInfo(scanner.lineStarts);

  AstBuilder builder = AstBuilder(
    reporter,
    source.uri,
    true,
    featureSet,
    lineInfo,
  );

  DartXParser parser = DartXParser(
    builder,
    allowPatterns: featureSet.isEnabled(Feature.patterns),
    scanner: scanner,
  );

  builder.parser = parser;

  Token token = scanner.tokenize();
  parser.parseUnit(token);

  Object? unit = builder.pop();

  if (unit is! CompilationUnit) {
    throw StateError('Expected CompilationUnit, got $unit');
  }

  DartFormatter formatter = DartFormatter();
  return formatter.format('$unit');
}
