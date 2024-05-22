// ignore_for_file: avoid_print, depend_on_referenced_packages

import 'package:dartx/dartx.dart';
import 'package:stack_trace/stack_trace.dart';

const String string = '''
import 'package:deact/deact.dart';

DeactNode app() {
  return <div>
    <span>1</span> a  b <span>2</span> c

     {showD ? d : txt('')}

    e <span>3</span>
  </div>;
}
''';

void main() {
  try {
    print(convert(string, url: Uri.file('app.dartx')));
  } catch (error, stackTrace) {
    print(error);
    print(Trace.format(stackTrace));
  }
}
