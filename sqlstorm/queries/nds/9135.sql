
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(ss.ss_net_paid) AS total_spent,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
    MAX(ss.ss_sold_date_sk) AS last_purchase_date,
    cd.cd_marital_status,
    cd.cd_gender,
    ca.ca_country AS location_country,
    COUNT(DISTINCT sw.ws_web_page_sk) AS total_web_visits
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales sw ON c.c_customer_sk = sw.ws_ship_customer_sk
WHERE 
    ss.ss_sold_date_sk BETWEEN 20220101 AND 20221231
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_marital_status, cd.cd_gender, ca.ca_country
HAVING 
    SUM(ss.ss_net_paid) > 500 AND COUNT(DISTINCT ss.ss_ticket_number) > 5
ORDER BY 
    total_spent DESC
LIMIT 10;
