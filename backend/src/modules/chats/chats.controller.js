const chatsService = require('./chats.service');

async function listMessages(req, res, next) {
  try {
    const messages = await chatsService.listMessagesForOrder(req.params.orderId, req.user);
    res.json({ messages });
  } catch (error) {
    next(error);
  }
}

async function sendMessage(req, res, next) {
  try {
    const message = await chatsService.sendMessageForOrder(
      req.params.orderId,
      req.user,
      req.body || {}
    );

    res.status(201).json({ message });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  listMessages,
  sendMessage,
};
