const usersStore = require('./users.store');

async function listUsers(_req, res, next) {
  try {
    const users = (await usersStore.listUsers()).map(({ passwordHash, ...safe }) => safe);
    res.json({ users });
  } catch (error) {
    next(error);
  }
}

async function me(req, res, next) {
  try {
    const user = await usersStore.findUserById(req.user.sub);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const { passwordHash, ...safeUser } = user;
    return res.json({ user: safeUser });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  listUsers,
  me,
};
