
SELECT 
    c.c_customer_id,
    SUM(CASE WHEN ws.ws_sold_date_sk BETWEEN 20220101 AND 20221231 THEN ws.ws_quantity ELSE 0 END) AS total_web_sales_quantity,
    SUM(CASE WHEN ss.ss_sold_date_sk BETWEEN 20220101 AND 20221231 THEN ss.ss_quantity ELSE 0 END) AS total_store_sales_quantity,
    SUM(CASE WHEN cr.cr_returned_date_sk BETWEEN 20220101 AND 20221231 THEN cr.cr_return_quantity ELSE 0 END) AS total_catalog_returns_quantity
FROM 
    customer c
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_web_sales_quantity DESC, total_store_sales_quantity DESC;
