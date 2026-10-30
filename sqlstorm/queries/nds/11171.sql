
SELECT 
    c.c_customer_id,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_store_sales,
    COUNT(DISTINCT ws.ws_order_number) AS total_web_sales,
    SUM(ss.ss_net_paid) AS total_store_net_paid,
    SUM(ws.ws_net_paid) AS total_web_net_paid
FROM 
    customer c
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_store_net_paid DESC, total_web_net_paid DESC
LIMIT 100;
