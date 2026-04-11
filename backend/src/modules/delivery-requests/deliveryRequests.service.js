const ApiError = require('../../utils/apiError');
const repository = require('./deliveryRequests.store');

async function listIncomingRequests(partnerId) {
  try {
    return repository.listIncomingRequestsForPartner(partnerId);
  } catch (error) {
    throw new ApiError(500, 'Failed to fetch delivery requests: ' + error.message);
  }
}

async function acceptRequest({ requestId, partnerId }) {
  try {
    const request = await repository.acceptRequest(requestId, partnerId);
    if (!request) {
      throw new ApiError(404, 'Delivery request not found');
    }
    return request;
  } catch (error) {
    if (error instanceof ApiError) throw error;
    throw new ApiError(400, 'Failed to accept delivery request: ' + error.message);
  }
}

async function rejectRequest({ requestId, partnerId, rejectionReason }) {
  try {
    const request = await repository.rejectRequest(requestId, partnerId, rejectionReason);
    if (!request) {
      throw new ApiError(404, 'Delivery request not found');
    }
    return request;
  } catch (error) {
    if (error instanceof ApiError) throw error;
    throw new ApiError(400, 'Failed to reject delivery request: ' + error.message);
  }
}

module.exports = {
  listIncomingRequests,
  acceptRequest,
  rejectRequest,
};
