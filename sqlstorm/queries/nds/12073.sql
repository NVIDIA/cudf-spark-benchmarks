
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    SUM(CASE WHEN ws.ws_item_sk IS NOT NULL THEN ws.ws_sales_price ELSE 0 END) AS total_web_sales,
    SUM(CASE WHEN cs.cs_item_sk IS NOT NULL THEN cs.cs_sales_price ELSE 0 END) AS total_catalog_sales,
    SUM(CASE WHEN ss.ss_item_sk IS NOT NULL THEN ss.ss_sales_price ELSE 0 END) AS total_store_sales
FROM 
    customer c
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name
ORDER BY 
    total_web_sales DESC, total_catalog_sales DESC, total_store_sales DESC
LIMIT 1000;
