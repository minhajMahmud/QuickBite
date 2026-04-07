const repository = require('./adminUsers.repository');
const ApiError = require('../../utils/apiError');

/**
 * List all users with filters
 */
async function listUsers({ role, status, limit, offset }) {
  try {
    const [users, total] = await Promise.all([
      repository.listUsersForAdmin({ role, status, limit, offset }),
      repository.countUsersForAdmin({ role, status }),
    ]);

    return {
      users,
      pagination: {
        total,
        limit,
        offset,
        hasMore: offset + users.length < total,
      },
    };
  } catch (error) {
    throw new ApiError(500, 'Failed to list users: ' + error.message);
  }
}

/**
 * Get detailed user information
 */
async function getUserDetails(userId) {
  try {
    const details = await repository.getUserDetailsForAdmin(userId);
    if (!details) {
      throw new ApiError(404, 'User not found');
    }
    return details;
  } catch (error) {
    if (error instanceof ApiError) throw error;
    throw new ApiError(500, 'Failed to fetch user details: ' + error.message);
  }
}

/**
 * Update user status (ban/unban/activate/deactivate)
 */
async function updateUserStatus({ userId, status }) {
  try {
    // Validate current user exists
    const current = await repository.findUserById(userId);
    if (!current) {
      throw new ApiError(404, 'User not found');
    }

    // Prevent banning admin users
    if (current.role === 'admin' && status === 'banned') {
      throw new ApiError(400, 'Cannot ban admin users');
    }

    const updated = await repository.updateUserStatus({ userId, status });
    if (!updated) {
      throw new ApiError(404, 'User not found');
    }

    return updated;
  } catch (error) {
    if (error instanceof ApiError) throw error;
    throw new ApiError(500, 'Failed to update user status: ' + error.message);
  }
}

/**
 * Get user statistics for dashboard
 */
async function getUserStatistics() {
  try {
    const stats = await repository.getUserStatistics();
    return stats;
  } catch (error) {
    throw new ApiError(500, 'Failed to fetch user statistics: ' + error.message);
  }
}

module.exports = {
  listUsers,
  getUserDetails,
  updateUserStatus,
  getUserStatistics,
};
