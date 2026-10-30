
SELECT 
    c.c_customer_id,
    COUNT(DISTINCT s.ss_ticket_number) AS total_store_sales,
    SUM(s.ss_net_profit) AS total_net_profit,
    SUM(s.ss_ext_discount_amt) AS total_discount
FROM 
    customer c
JOIN 
    store_sales s ON c.c_customer_sk = s.ss_customer_sk
JOIN 
    date_dim d ON s.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_net_profit DESC
LIMIT 100;
