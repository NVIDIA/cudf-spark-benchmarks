
SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_id) AS customer_count,
    SUM(ss_net_profit) AS total_net_profit
FROM 
    customer_address CA
JOIN 
    customer C ON CA.ca_address_sk = C.c_current_addr_sk
JOIN 
    store_sales SS ON C.c_customer_sk = SS.ss_customer_sk
JOIN 
    date_dim D ON SS.ss_sold_date_sk = D.d_date_sk
WHERE 
    D.d_year = 2023
GROUP BY 
    ca_state
ORDER BY 
    total_net_profit DESC;
