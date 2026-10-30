
SELECT 
    ca_state,
    SUM(ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ws_order_number) AS unique_orders,
    AVG(ws_net_profit) AS average_profit,
    COUNT(DISTINCT c_customer_id) AS unique_customers
FROM 
    web_sales
JOIN 
    customer ON ws_bill_customer_sk = c_customer_sk
JOIN 
    customer_address ON c_current_addr_sk = ca_address_sk
JOIN 
    date_dim ON ws_sold_date_sk = d_date_sk
WHERE 
    d_year = 2023
    AND d_month_seq BETWEEN 1 AND 12 
GROUP BY 
    ca_state
HAVING 
    SUM(ws_ext_sales_price) > 100000
ORDER BY 
    total_sales DESC
LIMIT 10;
