
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
    AVG(ss.ss_net_paid_inc_tax) AS average_spent,
    DENSE_RANK() OVER (PARTITION BY SUBSTRING(c.c_birth_country, 1, 2) ORDER BY SUM(ss.ss_net_profit) DESC) AS country_rank
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    dd.d_year = 2022 
    AND cd.cd_gender = 'F' 
    AND ss.ss_net_profit > 0
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, c.c_birth_country
HAVING 
    COUNT(DISTINCT ss.ss_ticket_number) > 5
ORDER BY 
    total_net_profit DESC
LIMIT 10;
