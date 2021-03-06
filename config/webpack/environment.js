const { environment } = require('@rails/webpacker')
const svelte = require('./loaders/svelte')
const coffee =  require('./loaders/coffee')
const html =  require('./loaders/html')
const markdown =  require('./loaders/markdown')
const json5 =  require('./loaders/json5')
const haml =  require('./loaders/haml')

environment.loaders.prepend('coffee', coffee)
environment.loaders.prepend('html', html)
environment.loaders.prepend('markdown', markdown)
environment.loaders.prepend('json5', json5)
environment.loaders.prepend('haml', haml)
environment.loaders.prepend('svelte', svelte)
module.exports = environment
