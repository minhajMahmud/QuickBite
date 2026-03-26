const usersStore = require('./users.store');

function listUsers(_req, res) {
  const users = usersStore.listUsers().map(({ passwordHash, ...safe }) => safe);
  res.json({ users });
}

function me(req, res) {
  const user = usersStore.findUserById(req.user.sub);
  if (!user) {
    return res.status(404).json({ message: 'User not found' });
  }

  const { passwordHash, ...safeUser } = user;
  return res.json({ user: safeUser });
}

module.exports = {
  listUsers,
  me,
};
