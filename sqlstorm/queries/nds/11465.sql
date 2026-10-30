
SELECT 
    customer.c_customer_id,
    SUM(store_sales.ss_sales_price) AS total_sales,
    COUNT(DISTINCT store_sales.ss_ticket_number) AS total_transactions,
    AVG(store_sales.ss_sales_price) AS avg_purchase_value
FROM 
    customer
JOIN 
    store_sales ON customer.c_customer_sk = store_sales.ss_customer_sk
WHERE 
    store_sales.ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
GROUP BY 
    customer.c_customer_id
ORDER BY 
    total_sales DESC
LIMIT 100;
