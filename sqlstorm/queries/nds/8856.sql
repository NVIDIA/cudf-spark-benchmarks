
SELECT 
    ca_city AS city,
    COUNT(DISTINCT c_customer_id) AS customer_count,
    SUM(ws_ext_sales_price) AS total_sales,
    AVG(ws_sales_price) AS avg_sales_price,
    d_year AS sales_year,
    cd_gender AS gender
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.ca_city IS NOT NULL
    AND dd.d_year BETWEEN 2020 AND 2023
GROUP BY 
    ca_city, d_year, cd_gender
HAVING 
    COUNT(DISTINCT c_customer_id) > 10
ORDER BY 
    total_sales DESC, city;
