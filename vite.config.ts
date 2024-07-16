import { defineConfig } from "vite"

export default defineConfig({
  assetsInclude: ['src/compile.wasm'],
  base: '',
  build: {
    emptyOutDir: true,
    outDir: 'docs',
    // rollupOptions: {
    //   output: {
    //     assetFileNames: "assets/[name].[ext]",
    //     chunkFileNames: "assets/[name].js",
    //   }
    // }
  },
  // worker: {
  //   rollupOptions: {
  //     output: {
  //       entryFileNames: "assets/[name].js",
  //     }
  //   }
  // },
})