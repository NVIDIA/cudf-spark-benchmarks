
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    SUM(COALESCE(ss.ss_sales_price, 0) + COALESCE(cs.cs_sales_price, 0) + COALESCE(ws.ws_sales_price, 0)) AS total_sales
FROM 
    customer c
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name
ORDER BY 
    total_sales DESC
LIMIT 100;
