
SELECT 
    c.c_customer_id,
    COUNT(DISTINCT s.ss_ticket_number) AS total_sales,
    SUM(s.ss_sales_price) AS total_revenue,
    AVG(s.ss_sales_price) AS average_sales_price,
    COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
    SUM(sr.sr_return_amt_inc_tax) AS total_return_amount
FROM 
    customer c
JOIN 
    store_sales s ON c.c_customer_sk = s.ss_customer_sk
LEFT JOIN 
    store_returns sr ON s.ss_item_sk = sr.sr_item_sk AND s.ss_ticket_number = sr.sr_ticket_number
WHERE 
    c.c_preferred_cust_flag = 'Y'
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_revenue DESC
LIMIT 100;
