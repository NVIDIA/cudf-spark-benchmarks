
SELECT 
    CA.ca_city, 
    COUNT(DISTINCT C.c_customer_sk) AS num_customers, 
    SUM(SS.ss_sales_price) AS total_sales
FROM 
    customer C
JOIN 
    customer_address CA ON C.c_current_addr_sk = CA.ca_address_sk
JOIN 
    store_sales SS ON C.c_customer_sk = SS.ss_customer_sk
JOIN 
    date_dim D ON SS.ss_sold_date_sk = D.d_date_sk
WHERE 
    D.d_year = 2023
GROUP BY 
    CA.ca_city
ORDER BY 
    total_sales DESC
LIMIT 10;
