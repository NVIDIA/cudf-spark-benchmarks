
SELECT 
    c.c_customer_id,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    MAX(ws.ws_sold_date_sk) AS last_order_date
FROM 
    customer AS c
JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    item AS i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    ws.ws_sold_date_sk >= 20230101
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_profit DESC
LIMIT 100;
