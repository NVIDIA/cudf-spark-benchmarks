
SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_sk) AS total_customers,
    COUNT(DISTINCT ws_order_number) AS total_orders,
    SUM(ws_quantity) AS total_quantity_sold,
    SUM(ws_net_paid) AS total_revenue
FROM 
    customer_address
JOIN 
    customer ON ca_address_sk = c_current_addr_sk
JOIN 
    web_sales ON c_customer_sk = ws_bill_customer_sk
GROUP BY 
    ca_state
ORDER BY 
    total_revenue DESC
LIMIT 10;
