const express = require('express');
const healthRoutes = require('../modules/health/health.routes');
const authRoutes = require('../modules/auth/auth.routes');
const usersRoutes = require('../modules/users/users.routes');
const ordersRoutes = require('../modules/orders/orders.routes');
const deliveryRequestsRoutes = require('../modules/delivery-requests/deliveryRequests.routes');
const deliveryTrackingRoutes = require('../modules/delivery-tracking/deliveryTracking.routes');
const restaurantDashboardRoutes = require('../modules/restaurant-dashboard/restaurantDashboard.routes');
const adminRestaurantsRoutes = require('../modules/admin-restaurants/adminRestaurants.routes');
const adminUsersRoutes = require('../modules/admin-users/adminUsers.routes');
const catalogRoutes = require('../modules/catalog/catalog.routes');
const offersRoutes = require('../modules/offers/offers.routes');
const chatsRoutes = require('../modules/chats/chats.routes');
const diagnosticRoutes = require('./diagnostic.routes');

const router = express.Router();

router.get('/', (_req, res) => {
  res.json({ message: 'QuickBite backend is running' });
});

router.use('/health', healthRoutes);

// Backward compatibility: some clients still call /restaurant-dashboard/*
// without the /api/v1 prefix.
router.use('/restaurant-dashboard', restaurantDashboardRoutes);

const apiRouter = express.Router();
apiRouter.use('/auth', authRoutes);
apiRouter.use('/users', usersRoutes);
apiRouter.use('/orders', ordersRoutes);
apiRouter.use('/delivery-requests', deliveryRequestsRoutes);
apiRouter.use('/delivery-tracking', deliveryTrackingRoutes);
apiRouter.use('/admin/restaurants', adminRestaurantsRoutes);
apiRouter.use('/admin/users', adminUsersRoutes);
apiRouter.use('/catalog', catalogRoutes);
apiRouter.use('/offers', offersRoutes);
apiRouter.use('/chats', chatsRoutes);
apiRouter.use('/restaurant-dashboard', restaurantDashboardRoutes);
apiRouter.use('/diagnostic', diagnosticRoutes);

router.use('/api/v1', apiRouter);

module.exports = router;
