
SELECT 
    c.c_customer_id, 
    COUNT(DISTINCT ss.ss_ticket_number) AS total_store_sales,
    SUM(ss.ss_net_profit) AS total_net_profit,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    MAX(ss.ss_sold_date_sk) AS last_purchase_date
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023 
    AND c.c_preferred_cust_flag = 'Y'
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_net_profit DESC
LIMIT 100;
