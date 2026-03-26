const express = require('express');
const validate = require('../../middlewares/validate');
const controller = require('./auth.controller');

const router = express.Router();

router.post('/register', validate(['name', 'email', 'password', 'role']), controller.register);
router.post('/login', validate(['email', 'password']), controller.login);

module.exports = router;
