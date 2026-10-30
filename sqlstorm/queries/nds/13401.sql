
SELECT 
    ca_state, 
    COUNT(DISTINCT c_customer_sk) AS customer_count, 
    SUM(ss_sales_price) AS total_sales 
FROM 
    customer_address CA 
JOIN 
    customer C ON CA.ca_address_sk = C.c_current_addr_sk 
JOIN 
    store_sales SS ON C.c_customer_sk = SS.ss_customer_sk 
JOIN 
    date_dim DD ON SS.ss_sold_date_sk = DD.d_date_sk 
WHERE 
    DD.d_year = 2023 
GROUP BY 
    ca_state 
ORDER BY 
    total_sales DESC 
LIMIT 10;
