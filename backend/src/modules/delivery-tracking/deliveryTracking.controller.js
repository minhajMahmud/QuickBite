const service = require('./deliveryTracking.service');
const events = require('./deliveryTracking.events');

async function getCurrentTracking(req, res, next) {
  try {
    const tracking = await service.getTrackingForPartner({
      orderId: req.params.orderId,
      partnerId: req.user.sub,
    });

    return res.json({ tracking });
  } catch (error) {
    return next(error);
  }
}

async function updateCurrentLocation(req, res, next) {
  try {
    const tracking = await service.updateTrackingForPartner({
      orderId: req.params.orderId,
      partnerId: req.user.sub,
      latitude: req.body?.latitude,
      longitude: req.body?.longitude,
    });

    events.emit('trackingUpdated', tracking);

    return res.json({
      message: 'Tracking location updated successfully',
      tracking,
    });
  } catch (error) {
    return next(error);
  }
}

async function streamTracking(req, res, next) {
  try {
    const orderId = req.params.orderId;
    const tracking = await service.getTrackingForPartner({
      orderId,
      partnerId: req.user.sub,
    });

    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    res.flushHeaders?.();

    const sendPayload = (payload) => {
      res.write('event: trackingUpdated\n');
      res.write(`data: ${JSON.stringify(payload)}\n\n`);
    };

    sendPayload(tracking);

    const heartbeat = setInterval(() => {
      res.write(': keep-alive\n\n');
    }, 20000);

    const listener = (payload) => {
      if (!payload || payload.orderId !== orderId) return;
      sendPayload(payload);
    };

    events.on('trackingUpdated', listener);

    req.on('close', () => {
      clearInterval(heartbeat);
      events.off('trackingUpdated', listener);
      res.end();
    });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  getCurrentTracking,
  updateCurrentLocation,
  streamTracking,
};
