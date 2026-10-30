
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT wr.wr_order_number) AS total_web_returns,
    COUNT(DISTINCT sr.sr_ticket_number) AS total_store_returns,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    SUM(sr.sr_return_amt) AS total_store_return_amount,
    SUM(CASE WHEN wr.wr_return_tax IS NOT NULL THEN wr.wr_return_tax ELSE 0 END) AS total_web_return_tax,
    SUM(CASE WHEN sr.sr_return_tax IS NOT NULL THEN sr.sr_return_tax ELSE 0 END) AS total_store_return_tax
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
LEFT JOIN 
    store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
WHERE 
    ca.ca_state IN ('CA', 'NY')
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
ORDER BY 
    total_web_return_amount DESC, total_store_return_amount DESC
LIMIT 50;
