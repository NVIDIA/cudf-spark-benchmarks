
SELECT 
    c.c_first_name,
    c.c_last_name,
    SUM(ss.ss_sales_price) AS total_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
    d.d_year,
    d.d_month_seq,
    d.d_day_name
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
    AND d.d_month_seq IN (10, 11)
    AND c.c_current_cdemo_sk IS NOT NULL
GROUP BY 
    c.c_first_name, c.c_last_name, d.d_year, d.d_month_seq, d.d_day_name
HAVING 
    SUM(ss.ss_sales_price) > 1000
ORDER BY 
    total_sales DESC, c.c_last_name ASC, c.c_first_name ASC
LIMIT 50;
