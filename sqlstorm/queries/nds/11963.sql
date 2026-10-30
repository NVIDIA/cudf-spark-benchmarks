
SELECT 
    c.c_customer_id,
    ca.ca_city,
    cs.cs_sales_price,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    SUM(ws.ws_net_profit) AS total_profit
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk
WHERE 
    ca.ca_state = 'CA'
    AND ws.ws_sold_date_sk BETWEEN 20000101 AND 20221231
GROUP BY 
    c.c_customer_id, 
    ca.ca_city, 
    cs.cs_sales_price
ORDER BY 
    total_profit DESC
LIMIT 100;
