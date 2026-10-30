SELECT 
    c.c_customer_id, 
    COUNT(o.ss_item_sk) AS total_items_sold, 
    SUM(o.ss_sales_price) AS total_sales, 
    SUM(o.ss_ext_tax) AS total_tax 
FROM 
    customer c 
JOIN 
    store_sales o ON c.c_customer_sk = o.ss_customer_sk 
WHERE 
    o.ss_sold_date_sk BETWEEN 2451545 AND 2451545 + 30 
GROUP BY 
    c.c_customer_id 
ORDER BY 
    total_sales DESC 
LIMIT 100;