
SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_sk) AS unique_customers,
    SUM(ss_quantity) AS total_sales_quantity,
    SUM(ss_net_paid) AS total_net_paid,
    AVG(ss_net_paid) AS avg_net_paid,
    MAX(ss_net_paid) AS max_net_paid,
    MIN(ss_net_paid) AS min_net_paid,
    COUNT(DISTINCT ss_ticket_number) AS total_transactions,
    AVG(i_current_price) AS avg_item_price,
    SUM(CASE WHEN cd_gender = 'M' THEN ss_quantity ELSE 0 END) AS male_sales_quantity,
    SUM(CASE WHEN cd_gender = 'F' THEN ss_quantity ELSE 0 END) AS female_sales_quantity
FROM 
    store_sales ss
JOIN 
    customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    item i ON ss.ss_item_sk = i.i_item_sk
JOIN 
    date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
WHERE 
    dd.d_year = 2023
GROUP BY 
    ca_state
ORDER BY 
    total_net_paid DESC
LIMIT 10;
