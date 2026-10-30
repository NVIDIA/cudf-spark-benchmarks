
SELECT 
    a.ca_city,
    d.d_year,
    SUM(s.ws_sales_price) AS total_sales
FROM 
    customer_address AS a 
JOIN 
    customer AS c ON a.ca_address_sk = c.c_current_addr_sk 
JOIN 
    web_sales AS s ON c.c_customer_sk = s.ws_bill_customer_sk 
JOIN 
    date_dim AS d ON s.ws_sold_date_sk = d.d_date_sk 
WHERE 
    d.d_year = 2022 
GROUP BY 
    a.ca_city, d.d_year 
ORDER BY 
    total_sales DESC 
LIMIT 10;
