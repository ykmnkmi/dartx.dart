import 'monaco-editor/esm/vs/editor/edcore.main';
import 'monaco-editor/esm/vs/basic-languages/dart/dart.contribution';

import { editor, Uri } from 'monaco-editor/esm/vs/editor/editor.api';

import editorWorker from 'monaco-editor/esm/vs/editor/editor.worker?worker';

import { instantiate, invoke } from './compile.js';

import compileUrl from './compile.wasm?url';

// @ts-ignore
self.MonacoEnvironment = {
  getWorker(workerID: any, label: string) {
    return new editorWorker();
  }
};

const EXAMPLE = `\
import 'package:deact/deact.dart';

DeactNode app() {
  return <Parent>Hello <Name name={<b>world</b>} />!</Parent>;
}
`;

const main = async () => {
  const module = WebAssembly.compileStreaming(fetch(compileUrl));
  const instance = await instantiate(module, {});
  invoke(instance);

  let editorModel = editor.createModel(EXAMPLE, 'dartx', Uri.parse('app.dartx'));
  let viewerModel = editor.createModel('', 'dart', Uri.parse('app.dart'));

  let onChange = () => {
    viewerModel.setValue(compile(editorModel.getValue()));
  };

  editorModel.onDidChangeContent(onChange);

  editor.create(document.querySelector('#editor')!, {
    automaticLayout: true,
    minimap: { enabled: false },
    model: editorModel,
    scrollBeyondLastLine: false,
    tabSize: 2,
  });

  editor.create(document.querySelector('#viewer')!, {
    automaticLayout: true,
    minimap: { enabled: false },
    model: viewerModel,
    scrollBeyondLastLine: false,
    tabSize: 2,
  });

  document.querySelector('#loading')!.remove();
  onChange();
};

main();