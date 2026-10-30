
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    SUM(ss.ss_net_paid_inc_tax) AS total_spent,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_purchases,
    AVG(ss.ss_net_paid_inc_tax) AS average_spent,
    cd.cd_gender,
    cd.cd_marital_status,
    d.d_year,
    d.d_month_seq
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023 
    AND cd.cd_gender = 'F'
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    d.d_year, 
    d.d_month_seq
HAVING 
    SUM(ss.ss_net_paid_inc_tax) > 1000
ORDER BY 
    total_spent DESC
LIMIT 10;
