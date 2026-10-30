
SELECT 
    c.c_customer_id,
    SUM(ss.ss_net_paid) AS total_sales,
    COUNT(ss.ss_ticket_number) AS total_transactions,
    AVG(ss.ss_net_paid) AS avg_transaction_value,
    DENSE_RANK() OVER (ORDER BY SUM(ss.ss_net_paid) DESC) AS sales_rank
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    ss.ss_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_sales DESC
LIMIT 10;
