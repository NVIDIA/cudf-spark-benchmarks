
SELECT 
    c.c_customer_id, 
    SUM(ss.ss_sales_price) AS total_sales, 
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions, 
    COUNT(DISTINCT cs.cs_order_number) AS total_catalog_sales,
    SUM(ss.ss_net_profit) AS total_net_profit
FROM 
    customer c
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
WHERE 
    c.c_preferred_cust_flag = 'Y'
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_sales DESC
LIMIT 100;
