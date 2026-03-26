const ApiError = require('../utils/apiError');

function validate(requiredFields = []) {
  return (req, _res, next) => {
    const missing = requiredFields.filter((field) => {
      const value = req.body?.[field];
      return value === undefined || value === null || value === '';
    });

    if (missing.length > 0) {
      return next(new ApiError(400, `Missing required fields: ${missing.join(', ')}`));
    }

    return next();
  };
}

module.exports = validate;
