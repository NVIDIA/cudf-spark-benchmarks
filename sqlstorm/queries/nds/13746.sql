
SELECT 
    c.c_customer_id,
    ca.ca_city,
    cd.cd_gender,
    SUM(ws.ws_sales_price) AS total_sales,
    COUNT(ws.ws_order_number) AS total_orders
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
WHERE 
    dd.d_year = 2023
GROUP BY 
    c.c_customer_id, ca.ca_city, cd.cd_gender
ORDER BY 
    total_sales DESC
LIMIT 100;
