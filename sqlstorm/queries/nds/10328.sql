
SELECT 
    c.c_customer_id,
    COUNT(os.ss_item_sk) AS total_sales,
    SUM(os.ss_sales_price) AS total_sales_amount,
    AVG(os.ss_sales_price) AS average_sales_price
FROM 
    customer AS c
JOIN 
    store_sales AS os ON c.c_customer_sk = os.ss_customer_sk
WHERE 
    c.c_birth_year >= 1980
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_sales_amount DESC
LIMIT 100;
