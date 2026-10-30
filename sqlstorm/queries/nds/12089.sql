
SELECT 
    i.i_item_id,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    SUM(ws.ws_sales_price) AS total_sales,
    AVG(ws.ws_net_profit) AS average_net_profit
FROM 
    web_sales ws
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    i.i_item_id
ORDER BY 
    total_sales DESC
LIMIT 10;
