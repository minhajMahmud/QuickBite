const { checkDbConnection } = require('../../config/db');

async function health(_req, res) {
  res.json({ status: 'ok', service: 'quickbite-backend' });
}

async function healthDb(_req, res, next) {
  try {
    const dbOk = await checkDbConnection();
    res.json({ status: dbOk ? 'ok' : 'failed', db: dbOk ? 'connected' : 'down' });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  health,
  healthDb,
};
