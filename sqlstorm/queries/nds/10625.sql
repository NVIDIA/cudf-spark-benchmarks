
SELECT 
    SUM(ss_net_paid) AS total_net_paid,
    COUNT(DISTINCT ss_customer_sk) AS total_customers,
    AVG(ss_sales_price) AS average_sales_price,
    MAX(ss_net_profit) AS max_net_profit,
    MIN(ss_ext_discount_amt) AS min_discount
FROM 
    store_sales 
WHERE 
    ss_sold_date_sk BETWEEN 10000 AND 20000;
