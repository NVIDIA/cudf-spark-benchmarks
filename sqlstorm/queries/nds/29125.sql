
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    ca.ca_city,
    ca.ca_state,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    AVG((ws.ws_ext_sales_price - ws.ws_ext_discount_amt) / NULLIF(ws.ws_ext_sales_price, 0)) * 100 AS avg_discount_percentage,
    COALESCE(SUBSTRING(UPPER(ca.ca_street_name), 1, 15), 'UNKNOWN') AS street_name_segment
FROM customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE ca.ca_state IN ('CA', 'TX')
GROUP BY c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, ca.ca_street_name
HAVING SUM(ws.ws_ext_sales_price) > 1000
ORDER BY total_sales DESC
LIMIT 10;
