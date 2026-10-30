
SELECT 
    c.c_customer_id, 
    SUM(ss.ss_sales_price) as total_sales,
    COUNT(ss.ss_ticket_number) as total_transactions,
    AVG(ss.ss_sales_price) as average_transaction_value,
    MAX(ss.ss_sales_price) as max_transaction_value,
    MIN(ss.ss_sales_price) as min_transaction_value
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_sales DESC
LIMIT 100;
