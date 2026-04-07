const service = require('./adminUsers.service');
const ApiError = require('../../utils/apiError');

/**
 * List all users with optional filters
 * GET /api/v1/admin/users
 */
async function listUsers(req, res, next) {
  try {
    const { role, status, limit = 50, offset = 0 } = req.query;

    const data = await service.listUsers({
      role,
      status,
      limit: Math.min(parseInt(limit, 10) || 50, 100),
      offset: Math.max(parseInt(offset, 10) || 0, 0),
    });

    res.json({
      message: 'Users retrieved successfully',
      ...data,
    });
  } catch (error) {
    next(error);
  }
}

/**
 * Get detailed information about a specific user
 * GET /api/v1/admin/users/:userId
 */
async function getUserDetails(req, res, next) {
  try {
    const { userId } = req.params;
    if (!userId) {
      throw new ApiError(400, 'User ID is required');
    }

    const details = await service.getUserDetails(userId);

    res.json({
      message: 'User details retrieved successfully',
      data: details,
    });
  } catch (error) {
    next(error);
  }
}

/**
 * Update user status (ban/unban/activate/deactivate)
 * PATCH /api/v1/admin/users/:userId/status
 */
async function updateUserStatus(req, res, next) {
  try {
    const { userId } = req.params;
    const { status } = req.body;

    if (!userId) {
      throw new ApiError(400, 'User ID is required');
    }

    if (!status) {
      throw new ApiError(400, 'Status is required');
    }

    if (!['active', 'inactive', 'banned'].includes(status)) {
      throw new ApiError(400, 'Invalid status. Must be one of: active, inactive, banned');
    }

    const updated = await service.updateUserStatus({ userId, status });

    // Determine the action message
    let actionMessage = 'User status updated';
    if (status === 'banned') {
      actionMessage = 'User has been banned successfully';
    } else if (status === 'active') {
      actionMessage = 'User has been activated successfully';
    } else if (status === 'inactive') {
      actionMessage = 'User has been deactivated successfully';
    }

    res.json({
      message: actionMessage,
      user: updated,
    });
  } catch (error) {
    next(error);
  }
}

/**
 * Get user statistics for admin dashboard
 * GET /api/v1/admin/users/statistics
 */
async function getUserStatistics(req, res, next) {
  try {
    const stats = await service.getUserStatistics();

    res.json({
      message: 'User statistics retrieved successfully',
      statistics: stats,
    });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  listUsers,
  getUserDetails,
  updateUserStatus,
  getUserStatistics,
};
