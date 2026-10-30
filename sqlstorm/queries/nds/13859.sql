
SELECT 
    c.c_customer_sk,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_sales_price) AS total_sales,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
FROM 
    customer c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    cd.cd_gender = 'F' AND 
    ws.ws_sold_date_sk BETWEEN 2450000 AND 2450010
GROUP BY 
    c.c_customer_sk
ORDER BY 
    total_sales DESC
LIMIT 100;
