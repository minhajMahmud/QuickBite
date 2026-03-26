const app = require('./app');
const env = require('./config/env');

app.listen(env.apiPort, () => {
  console.log(`QuickBite backend listening on port ${env.apiPort}`);
});
