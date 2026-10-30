
SELECT 
    c.c_customer_id, 
    COUNT(DISTINCT cs.cs_order_number) AS total_orders, 
    SUM(cs.cs_sales_price) AS total_revenue
FROM 
    customer AS c
JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    catalog_sales AS cs ON c.c_customer_sk = cs.cs_bill_customer_sk
WHERE 
    c.c_birth_year BETWEEN 1980 AND 1990
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_revenue DESC
LIMIT 100;
