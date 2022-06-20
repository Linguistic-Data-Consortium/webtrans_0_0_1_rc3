import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import { svelte } from '@sveltejs/vite-plugin-svelte';
import WindiCSS from 'vite-plugin-windicss'
import FullReload from 'vite-plugin-full-reload'
import { windi } from 'svelte-windicss-preprocess'
 
export default defineConfig({
  plugins: [
    RubyPlugin(),
    svelte({
      preprocess: [
        windi({}),
      ],
    }),
    WindiCSS({
        root: __dirname,
        scan: {
          fileExtensions: ['erb', 'haml', 'html', 'vue', 'js', 'ts', 'jsx', 'tsx', 'svelte'],
          dirs: ['app/views', 'app/javascript'],
        },
      }),
    // FullReload(['config/routes.rb', 'app/**/*'], { delay: 200 })
  ],
})
