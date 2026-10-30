
SELECT 
    ca_state, 
    SUM(ss_net_paid) AS total_sales 
FROM 
    store_sales 
JOIN 
    customer_address ON ss_addr_sk = ca_address_sk 
JOIN 
    date_dim ON ss_sold_date_sk = d_date_sk 
WHERE 
    d_year = 2023 
GROUP BY 
    ca_state 
ORDER BY 
    total_sales DESC;
