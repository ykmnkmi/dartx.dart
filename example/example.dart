// ignore_for_file: avoid_print, depend_on_referenced_packages

import 'package:dartx/dartx.dart';
import 'package:dartx/src/errors.dart';
import 'package:stack_trace/stack_trace.dart';

const String string = '''
import 'package:deact/deact.dart';

DeactNode app() {
  return <Parent a b="c">
    <p>1</p>
    <p>2</p>
    {<Child />}
  </Parent>;
}
''';

void main() {
  try {
    print(convert(string, url: Uri.file('app.dartx')));
  } on ParseError catch (error, stackTrace) {
    print(error.errorCode.message);
    print(error.span.highlight());
    print(Trace.format(stackTrace));
  } catch (error, stackTrace) {
    print(error);
    print(Trace.format(stackTrace));
  }
}
