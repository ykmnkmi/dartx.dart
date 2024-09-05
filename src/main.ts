import 'monaco-editor/esm/vs/editor/edcore.main';
import 'monaco-editor/esm/vs/basic-languages/dart/dart.contribution';

import { editor, Uri } from 'monaco-editor/esm/vs/editor/editor.api';

import editorWorker from 'monaco-editor/esm/vs/editor/editor.worker?worker';

import compileWasmUrl from './compile.wasm?url';
import compileJsUrl from './compile.dart.js?url';

// @ts-ignore
self.MonacoEnvironment = {
  getWorker(workerID: any, label: string) {
    return new editorWorker();
  }
};

const EXAMPLE = `\
import 'package:deact/deact.dart';

DeactNode app({User? user}) {
  DeactNode name;

  if (user == null) {
    name = <b>world</b>;
  } else {
    name = <b>{user.name}</b>;
  }

  return <Parent>Hello <Name name={name} />!</Parent>;
}
`;

const main = async () => {
  try {
    if (WebAssembly.validate(Uint8Array.of(0, 97, 115, 109, 1, 0, 0, 0, 1, 5, 1, 95, 1, 120, 0))) {
      const { instantiate, invoke } = await import('./compile.js');
      const module = WebAssembly.compileStreaming(fetch(compileWasmUrl));
      const instance = await instantiate(module, {});
      invoke(instance);
    } else {
      const script = document.createElement('script');
      script.type = 'text/javascript';
      script.src = compileJsUrl;

      const promise = new Promise((resolve, reject) => {
        script.addEventListener('load', () => {
          resolve(null);
        });

        script.addEventListener('error', () => {
          reject('Failed to load script: ' + compileJsUrl);
        });
      });

      document.head.appendChild(script);
      await promise;
    }
  } catch (error) {
    console.error(error);
    document.querySelector('#loading')!.textContent = `${error}`;
  }

  let editorModel = editor.createModel(EXAMPLE, 'dartx', Uri.parse('app.dartx'));
  let viewerModel = editor.createModel('', 'dart', Uri.parse('app.dart'));

  let onChange = () => {
    viewerModel.setValue(compile(editorModel.getValue()));
  };

  editorModel.onDidChangeContent(onChange);

  editor.create(document.querySelector('#editor')!, {
    automaticLayout: true,
    folding: false,
    fontFamily: 'DM Mono',
    lineNumbersMinChars: 3,
    minimap: { enabled: false },
    model: editorModel,
    scrollBeyondLastLine: false,
    tabSize: 2,
  });

  editor.create(document.querySelector('#viewer')!, {
    automaticLayout: true,
    folding: false,
    fontFamily: 'DM Mono',
    lineNumbersMinChars: 3,
    minimap: { enabled: false },
    model: viewerModel,
    readOnly: true,
    scrollBeyondLastLine: false,
    tabSize: 2,
  });

  document.querySelector('#loading')!.remove();
  onChange();
};

main();