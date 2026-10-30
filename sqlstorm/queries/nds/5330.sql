
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    SUM(ss.ss_sales_price) AS total_sales, 
    COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions, 
    d.d_year, 
    d.d_month_seq
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023 
    AND d.d_month_seq IN (1, 2, 3)
    AND c.c_preferred_cust_flag = 'Y'
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    d.d_year, 
    d.d_month_seq
HAVING 
    SUM(ss.ss_sales_price) > 1000
ORDER BY 
    total_sales DESC, 
    c.c_last_name, 
    c.c_first_name;
