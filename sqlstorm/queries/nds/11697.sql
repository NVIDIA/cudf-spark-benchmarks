
SELECT 
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    SUM(ss.ss_net_profit) AS total_net_profit,
    AVG(i.i_current_price) AS average_item_price,
    MAX(s.s_number_employees) AS max_employees_per_store,
    MIN(d.d_year) AS earliest_year
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    item i ON ss.ss_item_sk = i.i_item_sk
JOIN 
    store s ON ss.ss_store_sk = s.s_store_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year >= 2018
GROUP BY 
    d.d_year
ORDER BY 
    d.d_year;
