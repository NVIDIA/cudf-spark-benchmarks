
SELECT 
    ca_state, 
    COUNT(DISTINCT c_customer_sk) AS customer_count, 
    SUM(ss_sales_price) AS total_sales 
FROM 
    customer_address 
JOIN 
    customer ON ca_address_sk = c_current_addr_sk 
JOIN 
    store_sales ON c_customer_sk = ss_customer_sk 
JOIN 
    date_dim ON ss_sold_date_sk = d_date_sk 
GROUP BY 
    ca_state 
ORDER BY 
    total_sales DESC 
LIMIT 10;
