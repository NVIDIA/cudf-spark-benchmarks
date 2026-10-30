
SELECT 
    c.c_customer_id,
    SUM(ss.ss_net_paid) AS total_sales,
    COUNT(ss.ss_ticket_number) AS total_transactions,
    COUNT(DISTINCT ss.ss_item_sk) AS unique_items_sold
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    ss.ss_sold_date_sk BETWEEN 1000 AND 2000
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_sales DESC
LIMIT 100;
