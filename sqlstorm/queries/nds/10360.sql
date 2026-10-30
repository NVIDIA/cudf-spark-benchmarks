
SELECT 
    c.c_customer_id,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_store_sales,
    SUM(ss.ss_sales_price) AS total_sales_amount,
    COUNT(DISTINCT ws.ws_order_number) AS total_web_sales,
    SUM(ws.ws_sales_price) AS total_web_sales_amount
FROM 
    customer AS c
LEFT JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_ship_customer_sk
WHERE 
    c.c_current_cdemo_sk IS NOT NULL
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_sales_amount DESC;
