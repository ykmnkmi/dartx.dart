export function instantiate(
  modulePromise: Promise<WebAssembly.Module>,
  importObjectPromise: Object | Promise<Object>,
): Promise<WebAssembly.WebAssemblyInstantiatedSource>;

export function invoke(
  moduleInstance: WebAssembly.WebAssemblyInstantiatedSource,
  ...args: any[],
): void;

declare global {
  function compile(string: string): string
}
