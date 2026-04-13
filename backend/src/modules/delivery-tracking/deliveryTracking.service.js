const ApiError = require('../../utils/apiError');
const store = require('./deliveryTracking.store');

function toNumber(value) {
  if (typeof value === 'number') return value;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function haversineKm(lat1, lon1, lat2, lon2) {
  const toRad = (deg) => (deg * Math.PI) / 180;
  const r = 6371;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) *
      Math.cos(toRad(lat2)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return r * c;
}

function estimateEtaMinutes(context, riderLatitude, riderLongitude) {
  const drop = context.dropoff || {};
  if (
    !Number.isFinite(riderLatitude) ||
    !Number.isFinite(riderLongitude) ||
    !Number.isFinite(drop.latitude) ||
    !Number.isFinite(drop.longitude)
  ) {
    return null;
  }

  const distanceKm = haversineKm(
    riderLatitude,
    riderLongitude,
    drop.latitude,
    drop.longitude
  );

  const assumedSpeedKmPerHour = 28;
  const eta = Math.max(1, Math.round((distanceKm / assumedSpeedKmPerHour) * 60));
  return eta;
}

function normalizeTripState(orderStatus) {
  const status = String(orderStatus || '').toLowerCase();
  if (status === 'delivered') return 'delivered';
  if (status === 'on_the_way') return 'on_the_way';
  if (status === 'ready' || status === 'confirmed' || status === 'preparing') {
    return 'arrived_pickup';
  }
  return 'searching';
}

function buildTrackingPayload(context, { latitude, longitude } = {}) {
  const pickupLat = context.pickup?.latitude;
  const pickupLng = context.pickup?.longitude;

  const riderLat = Number.isFinite(latitude)
    ? latitude
    : Number.isFinite(context.rider?.latitude)
      ? context.rider.latitude
      : pickupLat;

  const riderLng = Number.isFinite(longitude)
    ? longitude
    : Number.isFinite(context.rider?.longitude)
      ? context.rider.longitude
      : pickupLng;

  return {
    orderId: context.orderId,
    requestId: context.requestId,
    state: normalizeTripState(context.orderStatus),
    orderStatus: context.orderStatus,
    etaMinutes: estimateEtaMinutes(context, riderLat, riderLng),
    pickup: {
      name: context.pickup?.name,
      latitude: context.pickup?.latitude,
      longitude: context.pickup?.longitude,
    },
    dropoff: {
      address: context.dropoff?.address,
      latitude: context.dropoff?.latitude,
      longitude: context.dropoff?.longitude,
    },
    rider: {
      name: context.rider?.name,
      phone: context.rider?.phone,
      latitude: riderLat,
      longitude: riderLng,
    },
    updatedAt: new Date().toISOString(),
  };
}

async function getTrackingForPartner({ orderId, partnerId }) {
  const context = await store.getAcceptedTrackingContext(orderId, partnerId);
  if (!context) {
    throw new ApiError(404, 'No active accepted delivery found for this order');
  }

  return buildTrackingPayload(context);
}

async function updateTrackingForPartner({ orderId, partnerId, latitude, longitude }) {
  const parsedLat = toNumber(latitude);
  const parsedLng = toNumber(longitude);

  if (!Number.isFinite(parsedLat) || !Number.isFinite(parsedLng)) {
    throw new ApiError(400, 'Valid latitude and longitude are required');
  }

  const context = await store.getAcceptedTrackingContext(orderId, partnerId);
  if (!context) {
    throw new ApiError(404, 'No active accepted delivery found for this order');
  }

  await store.updateDeliveryPartnerCurrentLocation({
    deliveryPartnerId: partnerId,
    latitude: parsedLat,
    longitude: parsedLng,
  });

  return buildTrackingPayload(context, {
    latitude: parsedLat,
    longitude: parsedLng,
  });
}

module.exports = {
  getTrackingForPartner,
  updateTrackingForPartner,
};
