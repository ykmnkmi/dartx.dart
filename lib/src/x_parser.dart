import 'package:_fe_analyzer_shared/src/parser/parser_impl.dart' as fe;
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/fasta/ast_builder.dart';
import 'package:dartx/src/errors.dart';
import 'package:dartx/src/html.dart';
import 'package:dartx/src/patterns.dart';
import 'package:dartx/src/x_scanner.dart';

mixin XParser on fe.Parser {
  @override
  AstBuilder get listener;

  XScanner get scanner;

  int parsed = 0;

  void push(Object object);

  Object? pop();

  String readTagName() {
    int start = scanner.scanOffset;

    String name = scanner.readUntil(tagNameEndRe).trim();

    if (name.isEmpty) {
      return '';
    }

    if (capitalLetter.hasMatch(name)) {
      error(capitalTagName);
    }

    if (validTagNameRe.hasMatch(name)) {
      return name;
    }

    scanner.error(invalidTagName, start);
  }

  Object? readMustache() {
    scanner.expect('{');
    scanner.allowSpace();
    scanner.scanOffset--;

    Token tail = scanner.tail;

    Token token = parseExpression(tail);
    Object? expression = pop();

    token.previous = null;
    token.next = null;

    tail.next = null;

    scanner.tail = tail;
    scanner.scanOffset = token.end;
    scanner.allowSpace();
    scanner.expect('}');
    return expression;
  }

  bool readAtribute() {
    String name = scanner.readUntil(attributeNameEndRe);

    if (name.isEmpty) {
      return false;
    }

    scanner.allowSpace();

    if (scanner.scan('=')) {
      scanner.allowSpace();
      String? quoteMark = scanner.read('"') ?? scanner.read("'");

      if (quoteMark != null) {
        String raw = scanner.readUntil(quoteMark);
        String data = decodeCharacterReferences(raw, true);
        push((name, data));
        scanner.expect(quoteMark);
      } else if (scanner.match('{')) {
        Object? expression = readMustache();
        push((name, expression));
      } else {
        scanner.error(missingAttributeValue);
      }
    } else {
      push((name, name));
    }

    return true;
  }

  void readSequence(Pattern end) {
    int start = scanner.scanOffset;
    List<Object?> children = <Object?>[];

    void flush(int end) {
      if (start < end) {
        String raw = scanner.string.substring(start, end);
        String data = decodeCharacterReferences(raw, true);
        children.add(data);
        start = end;
      }
    }

    while (!scanner.atEndOfFile()) {
      if (scanner.match(end)) {
        flush(scanner.scanOffset);
        push(children);
        return;
      }

      if (scanner.match('{')) {
        flush(scanner.scanOffset);
        children.add(readMustache());
        start = scanner.scanOffset;
      } else if (scanner.match('<')) {
        flush(scanner.scanOffset);
        parseTag();
        children.add(pop());
        start = scanner.scanOffset;
      } else {
        scanner.advance();
      }
    }
  }

  void parseFragment() {
    scanner.expect('>');

    RegExp closeTag = RegExp('<\\s*/\\s*>');
    readSequence(closeTag);
    scanner.expect(closeTag);

    List<Object?> children = pop() as List<Object?>;

    Object? value = pop();

    if (value != '') {
      error(expectedFragment);
    }

    push(('', <(String, Object)>[], children));
  }

  void parseElement(String name) {
    while (readAtribute()) {
      scanner.allowSpace();
    }

    scanner.allowSpace();

    bool selfClosing = scanner.scan('/');
    scanner.allowSpace();
    scanner.expect('>');

    if (selfClosing) {
      push(<Object?>[]);
    } else {
      RegExp closeTag = RegExp('<\\s*/\\s*$name\\s*>');
      readSequence(closeTag);
      scanner.expect(closeTag);
    }

    List<(String, Object)> properties = <(String, Object)>[];
    List<Object?> children = pop() as List<Object?>;

    while (true) {
      Object? value = pop();

      if (value == name) {
        break;
      }

      if (value is (String, Object)) {
        properties.add(value);
      } else {
        error(expectedProperty);
      }
    }

    push((name, properties, children));
  }

  void parseTag() {
    scanner.expect('<');
    scanner.allowSpace();

    String name = readTagName();
    scanner.allowSpace();
    push(name);

    if (name.isEmpty) {
      parseFragment();
    } else {
      parseElement(name);
    }
  }

  Token parseNode(Token token) {
    scanner.scanOffset = token.offset;

    Token previous = token.previous!;
    previous.next = null;

    Token tail = scanner.tail;
    tail.previous = null;
    tail.next = null;

    scanner.tail = previous;

    parseTag();

    Object? value = pop();

    if (value is! (String, List<(String, Object)>, List<Object?>)) {
      error(expectedTag);
    }

    var (tag, properties, children) = value;

    StringBuffer buffer = StringBuffer();

    if (tag.isEmpty) {
      if (children.isEmpty) {
        buffer.write('empty()');
      } else {
        buffer.write('fragment([');

        for (Object? child in children) {
          if (child is String) {
            buffer.write(escape(child));
          } else {
            buffer.write(child);
          }

          buffer.write(',');
        }

        buffer.write('])');
      }
    } else {
      buffer.write("el('$tag'");

      Object? key, ref;
      List<(String, Object)> attributes = <(String, Object)>[];
      List<(String, Object)> listeners = <(String, Object)>[];

      for (var (name, value) in properties) {
        if (name == 'key') {
          key = value;
        } else if (name == 'ref') {
          ref = value;
        } else if (name.startsWith('on')) {
          listeners.add((name, value));
        } else {
          attributes.add((name, value));
        }
      }

      if (key != null) {
        buffer
          ..write(', key: ')
          ..write(key);
      }

      if (ref != null) {
        buffer
          ..write(', ref: ')
          ..write(ref);
      }

      if (attributes.isNotEmpty) {
        buffer.write(', attributes: <String, Object>{');

        for (var (name, value) in attributes) {
          buffer.write("'$name': ");

          if (value is String) {
            buffer.write(escape(value));
          } else {
            buffer.write(value);
          }

          buffer.write(',');
        }

        buffer.write('}');
      }

      if (listeners.isNotEmpty) {
        buffer.write(', listeners: <String, Object>{');

        for (var (name, listener) in listeners) {
          buffer.write("'$name': ");

          if (listener is String) {
            buffer.write(escape(listener));
          } else {
            buffer.write(listener);
          }

          buffer.write(',');
        }

        buffer.write('}');
      }

      if (children.isNotEmpty) {
        buffer.write(', children: <Object>[');

        for (Object? child in children) {
          if (child is String) {
            buffer.write(escape(child));
          } else {
            buffer.write(child);
          }

          buffer.write(',');
        }

        buffer.write('],');
      }

      buffer.write(')');
    }

    String code = '$buffer';
    parsed = scanner.scanOffset;
    scanner.string = scanner.string.replaceRange(token.offset, parsed, code);
    parsed = token.offset + code.length;
    scanner.scanOffset = token.offset - 1;
    return super.parseExpression(scanner.tail);
  }

  Never error(ErrorCode errorCode, [int? position, int? end]) {
    scanner.error(errorCode, position, end);
  }
}

String escape(String value) {
  return "'${value.replaceAll("'", "\\'")}'";
}
