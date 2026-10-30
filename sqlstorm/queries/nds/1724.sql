
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) - 30 FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws.ws_item_sk
),
HighProfitItems AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_net_profit,
        ROW_NUMBER() OVER (ORDER BY sd.total_net_profit DESC) AS rank
    FROM 
        SalesData sd
    WHERE 
        sd.total_net_profit > 10000
),
ItemDetails AS (
    SELECT 
        i.i_item_sk, 
        i.i_item_desc,
        i.i_brand,
        i.i_current_price
    FROM 
        item i
    INNER JOIN 
        HighProfitItems hpi ON i.i_item_sk = hpi.ws_item_sk
)
SELECT 
    id.i_item_sk,
    id.i_item_desc,
    id.i_brand,
    id.i_current_price,
    COALESCE(SUM(ws.ws_quantity), 0) AS total_quantity_sold,
    COALESCE(AVG(ws.ws_net_profit), 0) AS avg_net_profit_per_sale
FROM 
    ItemDetails id
LEFT JOIN 
    web_sales ws ON id.i_item_sk = ws.ws_item_sk
GROUP BY 
    id.i_item_sk, id.i_item_desc, id.i_brand, id.i_current_price
HAVING 
    COUNT(ws.ws_order_number) > 10
ORDER BY 
    avg_net_profit_per_sale DESC
LIMIT 10;
