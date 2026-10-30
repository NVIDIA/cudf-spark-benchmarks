
SELECT 
    SUM(ss_net_profit) AS total_net_profit, 
    COUNT(DISTINCT ss_customer_sk) AS total_customers, 
    COUNT(DISTINCT ss_item_sk) AS total_items_sold
FROM 
    store_sales 
JOIN 
    date_dim ON store_sales.ss_sold_date_sk = date_dim.d_date_sk
WHERE 
    date_dim.d_year = 2023 
    AND date_dim.d_month_seq IN (1, 2, 3)
GROUP BY 
    date_dim.d_month_seq
ORDER BY 
    date_dim.d_month_seq;
