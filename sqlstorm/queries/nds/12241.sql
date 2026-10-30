
SELECT 
    c.c_customer_id,
    ca.ca_city,
    cd.cd_gender,
    SUM(ws.ws_sales_price) AS total_sales
FROM 
    customer AS c
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_customer_id, ca.ca_city, cd.cd_gender
ORDER BY 
    total_sales DESC
LIMIT 100;
