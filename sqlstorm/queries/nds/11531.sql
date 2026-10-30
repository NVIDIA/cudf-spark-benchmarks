
SELECT 
    c.c_customer_id, 
    COUNT(ss.ss_ticket_number) AS total_sales,
    SUM(ss.ss_net_paid_inc_tax) AS total_revenue,
    AVG(ss.ss_net_profit) AS average_profit,
    MAX(ss.ss_sold_date_sk) AS last_sale_date
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    item i ON ss.ss_item_sk = i.i_item_sk
WHERE 
    i.i_current_price > 50.00
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_revenue DESC
LIMIT 100;
