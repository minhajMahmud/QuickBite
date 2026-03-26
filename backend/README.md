# QuickBite Backend

A maintainable Express backend with a modular folder layout.

## Structure

- `src/config` - environment and DB configuration
- `src/modules` - feature modules (route + controller + service)
- `src/routes` - root API router
- `src/middlewares` - shared middleware and error handling

## Run locally

1. Copy `.env.example` to `.env`
2. Install dependencies
3. Start server (`npm run dev` or `npm start`)

## Health checks

- `GET /health` - basic service status
- `GET /health/db` - database connectivity status

## API routes

- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `GET /api/v1/users/me` (Bearer token)
- `GET /api/v1/users` (admin only)
- `GET /api/v1/orders` (role-aware listing)
- `POST /api/v1/orders`
- `PATCH /api/v1/orders/:id/status`

### Restaurant dashboard (admin/restaurant)

- `GET /api/v1/restaurant-dashboard/overview?restaurantId=rest-1`
- `GET /api/v1/restaurant-dashboard/menu?restaurantId=rest-1`
- `POST /api/v1/restaurant-dashboard/menu`
- `PATCH /api/v1/restaurant-dashboard/menu/:foodItemId`
- `GET /api/v1/restaurant-dashboard/orders?restaurantId=rest-1&status=pending&limit=20&offset=0`
- `PATCH /api/v1/restaurant-dashboard/orders/:orderId/status`
- `GET /api/v1/restaurant-dashboard/analytics?restaurantId=rest-1&days=30`
