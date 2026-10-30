
SELECT 
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(i.i_current_price) AS average_item_price
FROM 
    customer AS c
JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    item AS i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    ws.ws_sold_date_sk BETWEEN 1 AND 365
GROUP BY 
    c.c_customer_id
ORDER BY 
    unique_customers DESC
LIMIT 100;
