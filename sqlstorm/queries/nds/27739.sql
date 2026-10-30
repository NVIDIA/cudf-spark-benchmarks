
SELECT 
    ca_city,
    COUNT(DISTINCT c_customer_id) AS customer_count,
    COUNT(DISTINCT ws_order_number) AS total_orders,
    AVG(ws_net_profit) AS avg_net_profit,
    MAX(ws_sales_price) AS max_sales_price,
    MIN(ws_sales_price) AS min_sales_price,
    CONCAT('Total Customers: ', COUNT(DISTINCT c_customer_id), ', Total Orders: ', COUNT(DISTINCT ws_order_number)) AS summary_info
FROM 
    customer_address a
JOIN 
    customer c ON a.ca_address_sk = c.c_current_addr_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca_state = 'CA'
    AND ws_sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2023 
        AND d_month_seq BETWEEN 1 AND 12
    )
GROUP BY 
    ca_city
ORDER BY 
    customer_count DESC
LIMIT 10;
