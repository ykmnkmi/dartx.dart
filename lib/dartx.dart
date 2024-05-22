import 'package:_fe_analyzer_shared/src/scanner/scanner.dart'
    show ScannerConfiguration;
import 'package:analyzer/dart/analysis/features.dart' show Feature, FeatureSet;
import 'package:analyzer/error/listener.dart' show ErrorReporter;
import 'package:analyzer/source/line_info.dart' show LineInfo;
import 'package:analyzer/src/fasta/ast_builder.dart' show AstBuilder;
import 'package:analyzer/src/string_source.dart' show StringSource;
import 'package:dartx/src/parser.dart';
import 'package:dartx/src/scanner.dart';
import 'package:dartx/src/throwing_error_listener.dart';

String convert(String string, {Uri? url}) {
  string = string.trimRight();

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
  return parser.parse();
}
