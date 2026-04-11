-- Migration: Add delivery requests table for delivery partner accept/reject workflow
-- Created: April 11, 2026

CREATE TABLE IF NOT EXISTS delivery_requests (
    id VARCHAR(36) PRIMARY KEY,
    order_id VARCHAR(36) NOT NULL,
    delivery_partner_id VARCHAR(36) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'cancelled')),
    rejection_reason TEXT,
    responded_at TIMESTAMP,
    accepted_at TIMESTAMP,
    rejected_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_delivery_requests_order_partner UNIQUE (order_id, delivery_partner_id),
    CONSTRAINT fk_delivery_requests_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    CONSTRAINT fk_delivery_requests_partner FOREIGN KEY (delivery_partner_id) REFERENCES users(id) ON DELETE CASCADE
);
