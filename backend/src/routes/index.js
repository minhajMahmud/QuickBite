const express = require('express');
const healthRoutes = require('../modules/health/health.routes');
const authRoutes = require('../modules/auth/auth.routes');
const usersRoutes = require('../modules/users/users.routes');
const ordersRoutes = require('../modules/orders/orders.routes');
const restaurantDashboardRoutes = require('../modules/restaurant-dashboard/restaurantDashboard.routes');
const catalogRoutes = require('../modules/catalog/catalog.routes');
const offersRoutes = require('../modules/offers/offers.routes');
const diagnosticRoutes = require('./diagnostic.routes');

const router = express.Router();

router.get('/', (_req, res) => {
  res.json({ message: 'QuickBite backend is running' });
});

router.use('/health', healthRoutes);

const apiRouter = express.Router();
apiRouter.use('/auth', authRoutes);
apiRouter.use('/users', usersRoutes);
apiRouter.use('/orders', ordersRoutes);
apiRouter.use('/catalog', catalogRoutes);
apiRouter.use('/offers', offersRoutes);
apiRouter.use('/restaurant-dashboard', restaurantDashboardRoutes);
apiRouter.use('/diagnostic', diagnosticRoutes);

router.use('/api/v1', apiRouter);

module.exports = router;
