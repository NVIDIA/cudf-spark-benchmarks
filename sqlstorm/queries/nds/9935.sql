
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COUNT(DISTINCT s.ss_ticket_number) AS total_store_sales,
    SUM(s.ss_ext_sales_price) AS total_store_sales_amount,
    AVG(s.ss_net_profit) AS avg_store_net_profit,
    d.d_year,
    d.d_month_seq
FROM 
    customer c
JOIN 
    store_sales s ON c.c_customer_sk = s.ss_customer_sk
JOIN 
    date_dim d ON s.ss_sold_date_sk = d.d_date_sk
WHERE 
    c.c_birth_year BETWEEN 1980 AND 1995
    AND d.d_year >= 2020
    AND d.d_month_seq IN (1, 2, 3)
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, d.d_year, d.d_month_seq
ORDER BY 
    total_store_sales_amount DESC
LIMIT 100;
