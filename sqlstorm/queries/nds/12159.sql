
SELECT 
    ca_state, 
    COUNT(DISTINCT c_customer_sk) AS total_customers, 
    SUM(ss_quantity) AS total_sales_quantity, 
    SUM(ss_net_paid) AS total_sales_amount 
FROM 
    customer_address 
JOIN 
    customer ON ca_address_sk = c_current_addr_sk 
JOIN 
    store_sales ON c_customer_sk = ss_customer_sk 
JOIN 
    date_dim ON ss_sold_date_sk = d_date_sk 
WHERE 
    d_year = 2023 
GROUP BY 
    ca_state 
ORDER BY 
    total_sales_amount DESC 
LIMIT 10;
