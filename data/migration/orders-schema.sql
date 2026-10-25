-- Run against the optional RDS PostgreSQL database before testing the DMS task.
-- This creates only synthetic portfolio data; never use production data for the demo.
CREATE TABLE IF NOT EXISTS public.orders (
    order_id    VARCHAR(40) PRIMARY KEY,
    customer_id VARCHAR(40) NOT NULL,
    status      VARCHAR(20) NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL,
    order_total NUMERIC(12, 2) NOT NULL,
    currency    CHAR(3) NOT NULL
);

INSERT INTO public.orders (order_id, customer_id, status, created_at, order_total, currency)
VALUES
    ('ORDER#2026-0001', 'CUSTOMER#1001', 'PAID',    '2026-10-24T09:30:00Z',  39.95, 'INR'),
    ('ORDER#2026-0002', 'CUSTOMER#1001', 'PENDING', '2026-10-24T10:15:00Z', 125.00, 'INR'),
    ('ORDER#2026-0003', 'CUSTOMER#1002', 'PAID',    '2026-10-24T11:05:00Z',  79.50, 'INR')
ON CONFLICT (order_id) DO NOTHING;

SELECT status, COUNT(*) AS order_count, SUM(order_total) AS total_amount
FROM public.orders
GROUP BY status
ORDER BY status;
