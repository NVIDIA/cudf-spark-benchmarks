SELECT COUNT(*) AS total_orders
FROM orders
WHERE o_orderstatus = 'F';
