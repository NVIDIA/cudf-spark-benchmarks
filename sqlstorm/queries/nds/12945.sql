
SELECT 
    d.d_year, 
    d.d_month_seq, 
    COUNT(ss.ss_ticket_number) AS total_sales, 
    SUM(ss.ss_sales_price) AS total_revenue
FROM 
    store_sales ss
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN 
    store s ON ss.ss_store_sk = s.s_store_sk
JOIN 
    customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    d.d_year = 2023
    AND cd.cd_gender = 'F'
GROUP BY 
    d.d_year, 
    d.d_month_seq
ORDER BY 
    d.d_year, 
    d.d_month_seq;
