
SELECT 
    COUNT(DISTINCT c.c_customer_id) AS total_customers, 
    SUM(ws.ws_sales_price) AS total_sales, 
    AVG(cs.cs_sales_price) AS avg_catalog_sales 
FROM 
    customer c 
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
JOIN 
    catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk 
WHERE 
    c.c_current_cdemo_sk IS NOT NULL 
    AND ws.ws_sold_date_sk BETWEEN 1000 AND 2000 
    AND cs.cs_sold_date_sk BETWEEN 1000 AND 2000;
