
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    SUM(ss.ss_net_paid) AS total_spent,
    COUNT(ss.ss_ticket_number) AS total_purchases,
    COUNT(DISTINCT ss.ss_item_sk) AS unique_items_purchased,
    AVG(CASE WHEN ss.ss_sold_date_sk BETWEEN d.d_date_sk AND d.d_date_sk + 30 THEN ss.ss_net_paid ELSE NULL END) AS avg_spent_last_30_days,
    COUNT(DISTINCT CASE WHEN wr.wr_order_number IS NOT NULL THEN wr.wr_order_number END) AS total_web_returns
FROM 
    customer AS c
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    web_returns AS wr ON c.c_customer_sk = wr.wr_returning_customer_sk
JOIN 
    date_dim AS d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    ca.ca_state IN ('CA', 'NY')
    AND d.d_year = 2023
GROUP BY 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state
ORDER BY 
    total_spent DESC
LIMIT 100;
