export function instantiate(modulePromise: any, importObjectPromise: any): Promise<WebAssembly.WebAssemblyInstantiatedSource>;

export function invoke(moduleInstance: any, ...args: any[]): void;

declare global {
  function compile(string: string): string
}
