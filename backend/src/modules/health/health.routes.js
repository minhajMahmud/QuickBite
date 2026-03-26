const express = require('express');
const controller = require('./health.controller');

const router = express.Router();

router.get('/', controller.health);
router.get('/db', controller.healthDb);

module.exports = router;
