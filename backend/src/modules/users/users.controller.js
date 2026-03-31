const usersStore = require('./users.store');
const ApiError = require('../../utils/apiError');
const crypto = require('crypto');

async function listUsers(_req, res, next) {
  try {
    const users = (await usersStore.listUsers()).map(({ passwordHash, ...safe }) => safe);
    res.json({ users });
  } catch (error) {
    next(error);
  }
}

async function listPendingApprovals(_req, res, next) {
  try {
    const users = (await usersStore.listPendingApprovalUsers()).map(({ passwordHash, ...safe }) => safe);
    res.json({ users });
  } catch (error) {
    next(error);
  }
}

async function setUserApproval(req, res, next) {
  try {
    const userId = req.params.id;
    const approved = Boolean(req.body?.approved);

    if (!userId) {
      throw new ApiError(400, 'User id is required');
    }

    const user = await usersStore.findUserById(userId);
    if (!user) {
      throw new ApiError(404, 'User not found');
    }

    if (!['restaurant', 'delivery_partner'].includes(user.role)) {
      throw new ApiError(400, 'Only restaurant or delivery partner accounts require admin approval');
    }

    const updated = await usersStore.setApprovalStatus(userId, approved);
    if (!updated) {
      throw new ApiError(404, 'User not found');
    }

    const { passwordHash, ...safeUser } = updated;
    return res.json({
      message: approved ? 'Account approved successfully' : 'Account rejected successfully',
      user: safeUser,
    });
  } catch (error) {
    return next(error);
  }
}

async function me(req, res, next) {
  try {
    const user = await usersStore.findUserById(req.user.sub);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const savedAddresses = await usersStore.countAddressesByUser(req.user.sub);

    const { passwordHash, ...safeUser } = user;
    return res.json({
      user: {
        ...safeUser,
        savedAddresses,
      },
    });
  } catch (error) {
    return next(error);
  }
}

async function updateMe(req, res, next) {
  try {
    const allowedFields = ['name', 'email', 'phone', 'avatar', 'dateOfBirth', 'gender'];
    const payload = {};

    allowedFields.forEach((field) => {
      if (Object.prototype.hasOwnProperty.call(req.body || {}, field)) {
        const value = req.body[field];
        if (typeof value === 'string') {
          payload[field] = value.trim();
        } else {
          payload[field] = value;
        }
      }
    });

    if (Object.keys(payload).length === 0) {
      throw new ApiError(400, 'No updatable profile fields provided');
    }

    if (payload.email) {
      const existing = await usersStore.findUserByEmail(payload.email);
      if (existing && existing.id !== req.user.sub) {
        throw new ApiError(409, 'Email already registered');
      }
      payload.email = payload.email.toLowerCase();
    }

    if (payload.name !== undefined && !payload.name) {
      throw new ApiError(400, 'Name cannot be empty');
    }

    if (Object.prototype.hasOwnProperty.call(payload, 'dateOfBirth')) {
      if (payload.dateOfBirth === '' || payload.dateOfBirth === null) {
        payload.dateOfBirth = null;
      } else {
        const parsed = new Date(payload.dateOfBirth);
        if (Number.isNaN(parsed.getTime())) {
          throw new ApiError(400, 'Invalid dateOfBirth value');
        }
        payload.dateOfBirth = parsed.toISOString();
      }
    }

    if (Object.prototype.hasOwnProperty.call(payload, 'gender')) {
      if (payload.gender === '' || payload.gender === null) {
        payload.gender = null;
      }
    }

    const updated = await usersStore.updateUser(req.user.sub, payload);
    if (!updated) {
      throw new ApiError(404, 'User not found');
    }

    const {
      passwordHash,
      emailVerificationToken,
      passwordResetToken,
      ...safeUser
    } = updated;

    return res.json({
      message: 'Profile updated successfully',
      user: safeUser,
    });
  } catch (error) {
    return next(error);
  }
}

async function listMyAddresses(req, res, next) {
  try {
    const addresses = await usersStore.listAddressesByUser(req.user.sub);
    return res.json({ addresses });
  } catch (error) {
    return next(error);
  }
}

async function createMyAddress(req, res, next) {
  try {
    const {
      label,
      streetAddress,
      city,
      state,
      postalCode,
      country,
      isDefault,
    } = req.body || {};

    if (!streetAddress || !city || !state) {
      throw new ApiError(400, 'streetAddress, city and state are required');
    }

    const address = await usersStore.createAddress({
      id: crypto.randomUUID(),
      userId: req.user.sub,
      label: label || null,
      streetAddress: streetAddress.trim(),
      city: city.trim(),
      state: state.trim(),
      postalCode: postalCode || null,
      country: country || null,
      isDefault: Boolean(isDefault),
    });

    return res.status(201).json({
      message: 'Address added successfully',
      address,
    });
  } catch (error) {
    return next(error);
  }
}

async function updateMyAddress(req, res, next) {
  try {
    const addressId = req.params.id;
    if (!addressId) {
      throw new ApiError(400, 'Address id is required');
    }

    const patch = {};
    const allowed = [
      'label',
      'streetAddress',
      'city',
      'state',
      'postalCode',
      'country',
      'isDefault',
    ];

    allowed.forEach((field) => {
      if (!Object.prototype.hasOwnProperty.call(req.body || {}, field)) return;
      const value = req.body[field];
      patch[field] = typeof value === 'string' ? value.trim() : value;
    });

    const updated = await usersStore.updateAddress({
      addressId,
      userId: req.user.sub,
      patch,
    });

    if (!updated) {
      throw new ApiError(404, 'Address not found');
    }

    return res.json({
      message: 'Address updated successfully',
      address: updated,
    });
  } catch (error) {
    return next(error);
  }
}

async function deleteMyAddress(req, res, next) {
  try {
    const addressId = req.params.id;
    if (!addressId) {
      throw new ApiError(400, 'Address id is required');
    }

    const deleted = await usersStore.deleteAddress(addressId, req.user.sub);
    if (!deleted) {
      throw new ApiError(404, 'Address not found');
    }

    return res.json({ message: 'Address deleted successfully' });
  } catch (error) {
    return next(error);
  }
}

async function setMyDefaultAddress(req, res, next) {
  try {
    const addressId = req.params.id;
    if (!addressId) {
      throw new ApiError(400, 'Address id is required');
    }

    const updated = await usersStore.setDefaultAddress(addressId, req.user.sub);
    if (!updated) {
      throw new ApiError(404, 'Address not found');
    }

    return res.json({
      message: 'Default address updated',
      address: updated,
    });
  } catch (error) {
    return next(error);
  }
}

async function listMyFavorites(req, res, next) {
  try {
    const favorites = await usersStore.listFavoritesByUser(req.user.sub);
    return res.json({ favorites });
  } catch (error) {
    return next(error);
  }
}

async function addMyFavorite(req, res, next) {
  try {
    const restaurantId = req.body?.restaurantId;
    if (!restaurantId) {
      throw new ApiError(400, 'restaurantId is required');
    }

    const favoriteId = await usersStore.addFavorite({
      id: crypto.randomUUID(),
      userId: req.user.sub,
      restaurantId,
    });

    return res.status(201).json({
      message: 'Favorite saved',
      favoriteId,
    });
  } catch (error) {
    return next(error);
  }
}

async function removeMyFavorite(req, res, next) {
  try {
    const restaurantId = req.params.restaurantId;
    if (!restaurantId) {
      throw new ApiError(400, 'restaurantId is required');
    }

    const removed = await usersStore.removeFavoriteByRestaurant(
      req.user.sub,
      restaurantId
    );
    if (!removed) {
      throw new ApiError(404, 'Favorite not found');
    }

    return res.json({ message: 'Favorite removed' });
  } catch (error) {
    return next(error);
  }
}

async function listMyNotifications(req, res, next) {
  try {
    const notifications = await usersStore.listNotificationsByUser(req.user.sub);
    return res.json({ notifications });
  } catch (error) {
    return next(error);
  }
}

async function markMyNotificationsRead(req, res, next) {
  try {
    await usersStore.markAllNotificationsReadByUser(req.user.sub);
    return res.json({ message: 'Notifications marked as read' });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  listUsers,
  listPendingApprovals,
  setUserApproval,
  me,
  updateMe,
  listMyAddresses,
  createMyAddress,
  updateMyAddress,
  deleteMyAddress,
  setMyDefaultAddress,
  listMyFavorites,
  addMyFavorite,
  removeMyFavorite,
  listMyNotifications,
  markMyNotificationsRead,
};
