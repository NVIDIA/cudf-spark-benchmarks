
SELECT 
    ca_city, 
    COUNT(DISTINCT c_customer_sk) AS num_customers, 
    SUM(ws_ext_sales_price) AS total_sales
FROM 
    customer_address 
JOIN 
    customer ON ca_address_sk = c_current_addr_sk 
JOIN 
    web_sales ON c_customer_sk = ws_bill_customer_sk 
JOIN 
    date_dim ON ws_sold_date_sk = d_date_sk 
WHERE 
    d_year = 2023
GROUP BY 
    ca_city
ORDER BY 
    total_sales DESC
LIMIT 10;
