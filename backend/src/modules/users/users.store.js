const users = new Map();

function createUser(user) {
  users.set(user.id, user);
  return user;
}

function findUserByEmail(email) {
  const normalized = String(email).toLowerCase();
  for (const user of users.values()) {
    if (String(user.email).toLowerCase() === normalized) {
      return user;
    }
  }
  return null;
}

function findUserById(id) {
  return users.get(id) || null;
}

function listUsers() {
  return Array.from(users.values());
}

module.exports = {
  createUser,
  findUserByEmail,
  findUserById,
  listUsers,
};
