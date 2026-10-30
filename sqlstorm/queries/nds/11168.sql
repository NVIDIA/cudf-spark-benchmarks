
SELECT 
    COUNT(DISTINCT c_customer_sk) AS unique_customers,
    SUM(ss_sales_price) AS total_sales,
    AVG(ss_net_profit) AS avg_net_profit
FROM 
    store_sales ss
JOIN 
    customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
    AND ss.ss_quantity > 0
GROUP BY 
    d.d_month_seq
ORDER BY 
    d.d_month_seq;
