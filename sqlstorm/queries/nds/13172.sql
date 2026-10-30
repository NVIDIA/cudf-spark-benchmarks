
SELECT 
    SUM(ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT ss_customer_sk) AS total_customers,
    COUNT(DISTINCT ss_ticket_number) AS total_transactions,
    AVG(ss_sales_price) AS avg_sales_price
FROM 
    store_sales
WHERE 
    ss_sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2023
    )
GROUP BY 
    ss_store_sk
ORDER BY 
    total_net_profit DESC
LIMIT 10;
