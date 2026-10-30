
SELECT 
    COUNT(*) AS total_sales,
    SUM(ss_net_paid) AS total_revenue,
    AVG(ss_list_price) AS average_list_price,
    MIN(ss_sales_price) AS min_sales_price,
    MAX(ss_sales_price) AS max_sales_price,
    s_store_name
FROM 
    store_sales
JOIN 
    store ON store_sales.ss_store_sk = store.s_store_sk
WHERE 
    ss_sold_date_sk BETWEEN 1 AND 1000
GROUP BY 
    s_store_name
ORDER BY 
    total_sales DESC;
