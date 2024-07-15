final RegExp spaceRe = RegExp('\\s*');

final RegExp textEndRe = RegExp('[<{]');

final RegExp openingCurlyRe = RegExp('{\\s*');

final RegExp closingCurlyRe = RegExp('\\s*}');

final RegExp capitalLetter = RegExp('[A-Z]+');

final RegExp tagNameEndRe = RegExp('(\\s|\\/|>)');

final RegExp validTagNameRe = RegExp('^\\!?[a-zA-Z]{1,}:?[a-zA-Z0-9\\-.]*');

final RegExp attributeNameEndRe = RegExp('[\\s=\\/>"\'{]');
