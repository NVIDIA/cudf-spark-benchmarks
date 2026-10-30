
SELECT 
    ca_state, 
    COUNT(DISTINCT c_customer_sk) AS customer_count, 
    SUM(ws_ext_sales_price) AS total_sales 
FROM 
    customer_address AS ca 
JOIN 
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk 
JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
JOIN 
    date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk 
WHERE 
    d.d_year = 2023 
GROUP BY 
    ca_state 
ORDER BY 
    total_sales DESC 
LIMIT 10;
