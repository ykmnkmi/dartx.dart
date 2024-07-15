let buildArgsList;

// `modulePromise` is a promise to the `WebAssembly.module` object to be
//   instantiated.
// `importObjectPromise` is a promise to an object that contains any additional
//   imports needed by the module that aren't provided by the standard runtime.
//   The fields on this object will be merged into the importObject with which
//   the module will be instantiated.
// This function returns a promise to the instantiated module.
export const instantiate = async (modulePromise, importObjectPromise) => {
    let dartInstance;

    function stringFromDartString(string) {
        const totalLength = dartInstance.exports.$stringLength(string);
        let result = '';
        let index = 0;
        while (index < totalLength) {
          let chunkLength = Math.min(totalLength - index, 0xFFFF);
          const array = new Array(chunkLength);
          for (let i = 0; i < chunkLength; i++) {
              array[i] = dartInstance.exports.$stringRead(string, index++);
          }
          result += String.fromCharCode(...array);
        }
        return result;
    }

    function stringToDartString(string) {
        const length = string.length;
        let range = 0;
        for (let i = 0; i < length; i++) {
            range |= string.codePointAt(i);
        }
        if (range < 256) {
            const dartString = dartInstance.exports.$stringAllocate1(length);
            for (let i = 0; i < length; i++) {
                dartInstance.exports.$stringWrite1(dartString, i, string.codePointAt(i));
            }
            return dartString;
        } else {
            const dartString = dartInstance.exports.$stringAllocate2(length);
            for (let i = 0; i < length; i++) {
                dartInstance.exports.$stringWrite2(dartString, i, string.charCodeAt(i));
            }
            return dartString;
        }
    }

    // Prints to the console
    function printToConsole(value) {
      if (typeof dartPrint == "function") {
        dartPrint(value);
        return;
      }
      if (typeof console == "object" && typeof console.log != "undefined") {
        console.log(value);
        return;
      }
      if (typeof print == "function") {
        print(value);
        return;
      }

      throw "Unable to print message: " + js;
    }

    // Converts a Dart List to a JS array. Any Dart objects will be converted, but
    // this will be cheap for JSValues.
    function arrayFromDartList(constructor, list) {
        const length = dartInstance.exports.$listLength(list);
        const array = new constructor(length);
        for (let i = 0; i < length; i++) {
            array[i] = dartInstance.exports.$listRead(list, i);
        }
        return array;
    }

    buildArgsList = function(list) {
        const dartList = dartInstance.exports.$makeStringList();
        for (let i = 0; i < list.length; i++) {
            dartInstance.exports.$listAdd(dartList, stringToDartString(list[i]));
        }
        return dartList;
    }

    // A special symbol attached to functions that wrap Dart functions.
    const jsWrappedDartFunctionSymbol = Symbol("JSWrappedDartFunction");

    function finalizeWrapper(dartFunction, wrapped) {
        wrapped.dartFunction = dartFunction;
        wrapped[jsWrappedDartFunctionSymbol] = true;
        return wrapped;
    }

    // Imports
    const dart2wasm = {

_75: x0 => globalThis.compile = x0,
_76: f => finalizeWrapper(f,x0 => dartInstance.exports._76(f,x0)),
_1875: () => globalThis.window,
_12720: v => stringToDartString(v.toString()),
_12734: s => {
      const jsSource = stringFromDartString(s);
      if (!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(jsSource)) {
        return NaN;
      }
      return parseFloat(jsSource);
    },
_12735: () => {
          let stackString = new Error().stack.toString();
          let frames = stackString.split('\n');
          let drop = 2;
          if (frames[0] === 'Error') {
              drop += 1;
          }
          return frames.slice(drop).join('\n');
        },
_12739: () => {
      // On browsers return `globalThis.location.href`
      if (globalThis.location != null) {
        return stringToDartString(globalThis.location.href);
      }
      return null;
    },
_12740: () => {
        return typeof process != undefined &&
               Object.prototype.toString.call(process) == "[object process]" &&
               process.platform == "win32"
      },
_12744: s => stringToDartString(JSON.stringify(stringFromDartString(s))),
_12745: s => printToConsole(stringFromDartString(s)),
_12763: (c) =>
              queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
_12765: (a, i) => a.push(i),
_12766: (a, i) => a.splice(i, 1)[0],
_12769: a => a.pop(),
_12775: (a, b) => a == b ? 0 : (a > b ? 1 : -1),
_12776: a => a.length,
_12778: (a, i) => a[i],
_12779: (a, i, v) => a[i] = v,
_12781: a => a.join(''),
_12782: (o, a, b) => o.replace(a, b),
_12784: (s, t) => s.split(t),
_12785: s => s.toLowerCase(),
_12786: s => s.toUpperCase(),
_12787: s => s.trim(),
_12788: s => s.trimLeft(),
_12789: s => s.trimRight(),
_12791: (s, p, i) => s.indexOf(p, i),
_12792: (s, p, i) => s.lastIndexOf(p, i),
_12794: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
_12795: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
_12796: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
_12797: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
_12798: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
_12799: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
_12800: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
_12803: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
_12804: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
_12805: Object.is,
_12808: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
_12812: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
_12813: (b, o) => new DataView(b, o),
_12815: Function.prototype.call.bind(DataView.prototype.getUint8),
_12816: Function.prototype.call.bind(DataView.prototype.setUint8),
_12817: Function.prototype.call.bind(DataView.prototype.getInt8),
_12818: Function.prototype.call.bind(DataView.prototype.setInt8),
_12819: Function.prototype.call.bind(DataView.prototype.getUint16),
_12820: Function.prototype.call.bind(DataView.prototype.setUint16),
_12821: Function.prototype.call.bind(DataView.prototype.getInt16),
_12822: Function.prototype.call.bind(DataView.prototype.setInt16),
_12823: Function.prototype.call.bind(DataView.prototype.getUint32),
_12824: Function.prototype.call.bind(DataView.prototype.setUint32),
_12825: Function.prototype.call.bind(DataView.prototype.getInt32),
_12826: Function.prototype.call.bind(DataView.prototype.setInt32),
_12831: Function.prototype.call.bind(DataView.prototype.getFloat32),
_12832: Function.prototype.call.bind(DataView.prototype.setFloat32),
_12833: Function.prototype.call.bind(DataView.prototype.getFloat64),
_12834: Function.prototype.call.bind(DataView.prototype.setFloat64),
_12840: s => stringToDartString(stringFromDartString(s).toUpperCase()),
_12841: s => stringToDartString(stringFromDartString(s).toLowerCase()),
_12843: (s, m) => {
          try {
            return new RegExp(s, m);
          } catch (e) {
            return String(e);
          }
        },
_12844: (x0,x1) => x0.exec(x1),
_12845: (x0,x1) => x0.test(x1),
_12846: (x0,x1) => x0.exec(x1),
_12847: (x0,x1) => x0.exec(x1),
_12848: x0 => x0.pop(),
_12854: o => o === undefined,
_12855: o => typeof o === 'boolean',
_12856: o => typeof o === 'number',
_12858: o => typeof o === 'string',
_12861: o => o instanceof Int8Array,
_12862: o => o instanceof Uint8Array,
_12863: o => o instanceof Uint8ClampedArray,
_12864: o => o instanceof Int16Array,
_12865: o => o instanceof Uint16Array,
_12866: o => o instanceof Int32Array,
_12867: o => o instanceof Uint32Array,
_12868: o => o instanceof Float32Array,
_12869: o => o instanceof Float64Array,
_12870: o => o instanceof ArrayBuffer,
_12871: o => o instanceof DataView,
_12872: o => o instanceof Array,
_12873: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
_12876: o => o instanceof RegExp,
_12877: (l, r) => l === r,
_12878: o => o,
_12879: o => o,
_12880: o => o,
_12881: b => !!b,
_12882: o => o.length,
_12885: (o, i) => o[i],
_12886: f => f.dartFunction,
_12887: l => arrayFromDartList(Int8Array, l),
_12888: l => arrayFromDartList(Uint8Array, l),
_12889: l => arrayFromDartList(Uint8ClampedArray, l),
_12890: l => arrayFromDartList(Int16Array, l),
_12891: l => arrayFromDartList(Uint16Array, l),
_12892: l => arrayFromDartList(Int32Array, l),
_12893: l => arrayFromDartList(Uint32Array, l),
_12894: l => arrayFromDartList(Float32Array, l),
_12895: l => arrayFromDartList(Float64Array, l),
_12896: (data, length) => {
          const view = new DataView(new ArrayBuffer(length));
          for (let i = 0; i < length; i++) {
              view.setUint8(i, dartInstance.exports.$byteDataGetUint8(data, i));
          }
          return view;
        },
_12897: l => arrayFromDartList(Array, l),
_12898: stringFromDartString,
_12899: stringToDartString,
_12902: l => new Array(l),
_12906: (o, p) => o[p],
_12910: o => String(o),
_12914: x0 => x0.input,
_12915: x0 => x0.index,
_12917: x0 => x0.length,
_12919: (x0,x1) => x0[x1],
_12921: (x0,x1) => x0.exec(x1),
_12923: x0 => x0.flags,
_12924: x0 => x0.multiline,
_12925: x0 => x0.ignoreCase,
_12926: x0 => x0.unicode,
_12927: x0 => x0.dotAll,
_12928: (x0,x1) => x0.lastIndex = x1
    };

    const baseImports = {
        dart2wasm: dart2wasm,


        Math: Math,
        Date: Date,
        Object: Object,
        Array: Array,
        Reflect: Reflect,
    };

    const jsStringPolyfill = {
        "charCodeAt": (s, i) => s.charCodeAt(i),
        "compare": (s1, s2) => {
            if (s1 < s2) return -1;
            if (s1 > s2) return 1;
            return 0;
        },
        "concat": (s1, s2) => s1 + s2,
        "equals": (s1, s2) => s1 === s2,
        "fromCharCode": (i) => String.fromCharCode(i),
        "length": (s) => s.length,
        "substring": (s, a, b) => s.substring(a, b),
    };

    dartInstance = await WebAssembly.instantiate(await modulePromise, {
        ...baseImports,
        ...(await importObjectPromise),
        "wasm:js-string": jsStringPolyfill,
    });

    return dartInstance;
}

// Call the main function for the instantiated module
// `moduleInstance` is the instantiated dart2wasm module
// `args` are any arguments that should be passed into the main function.
export const invoke = (moduleInstance, ...args) => {
    const dartMain = moduleInstance.exports.$getMain();
    const dartArgs = buildArgsList(args);
    moduleInstance.exports.$invokeMain(dartMain, dartArgs);
}

