
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(ss.ss_net_paid) AS total_spent,
    COUNT(DISTINCT ss.ss_ticket_number) AS purchase_count,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    MAX(ss.ss_sold_date_sk) AS last_purchase_date,
    d.d_year,
    CASE 
        WHEN cd.cd_gender = 'F' THEN 'Female'
        WHEN cd.cd_gender = 'M' THEN 'Male'
        ELSE 'Other'
    END AS gender,
    r.r_reason_desc
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
LEFT JOIN 
    store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number AND ss.ss_item_sk = sr.sr_item_sk
LEFT JOIN 
    reason r ON sr.sr_reason_sk = r.r_reason_sk
WHERE 
    d.d_year >= 2020
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, d.d_year, cd.cd_gender, r.r_reason_desc
HAVING 
    SUM(ss.ss_net_paid) > 1000
ORDER BY 
    total_spent DESC;
