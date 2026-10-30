
SELECT 
    c.c_customer_id, 
    SUM(ss.ss_sales_price) AS total_sales,
    COUNT(ss.ss_item_sk) AS total_items_sold,
    d.d_year AS sales_year
FROM 
    store_sales ss
JOIN 
    customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year BETWEEN 2022 AND 2023
GROUP BY 
    c.c_customer_id, d.d_year
ORDER BY 
    total_sales DESC
LIMIT 100;
