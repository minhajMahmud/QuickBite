const EventEmitter = require('events');

const ordersEvents = new EventEmitter();
ordersEvents.setMaxListeners(100);

module.exports = ordersEvents;
