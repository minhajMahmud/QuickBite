const EventEmitter = require('events');

const deliveryTrackingEvents = new EventEmitter();
deliveryTrackingEvents.setMaxListeners(200);

module.exports = deliveryTrackingEvents;
