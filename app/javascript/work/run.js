import Script from '../script/script.svelte'
let x = () => {
    return {
      run: (hash) => {
          window.permissions = hash;
          document.querySelector('.Header').remove()
          let h = {
              id: 'node-0',
              error: hash.error,
              debug: (hash.admin || hash.portal_manager || hash.project_manager)
            }
          let app = new Script({
              target: document.getElementById('main'),
              props: h
            });
      }
    }
  }
window.ldc_run = x();
export { x }
