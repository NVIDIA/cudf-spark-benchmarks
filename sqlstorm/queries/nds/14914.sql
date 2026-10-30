
SELECT 
    c.c_customer_id,
    COALESCE(SUM(ss.ss_sales_price), 0) AS total_store_sales,
    COALESCE(SUM(ws.ws_sales_price), 0) AS total_web_sales
FROM 
    customer c
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_store_sales DESC, total_web_sales DESC
LIMIT 100;
