// ignore_for_file: avoid_print, depend_on_referenced_packages

import 'dart:convert';
import 'dart:js_interop';

import 'package:dartx/dartx.dart';
import 'package:dartx/src/errors.dart';
import 'package:stack_trace/stack_trace.dart';

@JS('compile')
external set jsCompile(JSFunction compile);

void main() {
  jsCompile = compile.toJS;
}

String compile(String string) {
  try {
    return convert(string, url: Uri.file('app.dartx'));
  } on ParseError catch (error) {
    return format('${error.errorCode.message}\n${error.span.highlight()}');
  } catch (error, stackTrace) {
    return format('$error\n${Trace.format(stackTrace)}');
  }
}

String format(String string) {
  return const LineSplitter()
      .convert(string)
      .map((line) => '// $line')
      .join('\n');
}
