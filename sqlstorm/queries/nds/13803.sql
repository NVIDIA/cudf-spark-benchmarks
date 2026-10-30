
SELECT 
    c.c_customer_id,
    SUM(ss.ss_sales_price) AS total_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
    COUNT(DISTINCT sr.sr_ticket_number) AS total_returns
FROM 
    customer c
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    store_returns sr ON ss.ss_item_sk = sr.sr_item_sk AND ss.ss_ticket_number = sr.sr_ticket_number
WHERE 
    c.c_current_addr_sk IN (
        SELECT ca_address_sk 
        FROM customer_address 
        WHERE ca_state = 'CA'
    )
GROUP BY 
    c.c_customer_id
HAVING 
    SUM(ss.ss_sales_price) > 1000
ORDER BY 
    total_sales DESC;
