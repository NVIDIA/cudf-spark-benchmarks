
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(ss.ss_quantity) AS total_quantity_sold,
    SUM(ss.ss_sales_price) AS total_sales,
    AVG(ss.ss_net_profit) AS avg_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
    d.d_year,
    d.d_month_seq,
    d.d_week_seq
FROM 
    customer AS c
JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim AS d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    cd.cd_gender = 'F' 
    AND d.d_year BETWEEN 2019 AND 2022
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    d.d_year, 
    d.d_month_seq, 
    d.d_week_seq
HAVING 
    SUM(ss.ss_sales_price) > 1000
ORDER BY 
    total_sales DESC
LIMIT 100;
