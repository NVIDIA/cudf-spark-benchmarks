
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_profit
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        store s ON ws.ws_warehouse_sk = s.s_store_sk
    WHERE 
        i.i_current_price > 0
    GROUP BY 
        ws.ws_item_sk
),
TopProfitableItems AS (
    SELECT 
        r.ws_item_sk,
        r.total_quantity,
        r.total_profit,
        r.rank_profit, 
        i.i_item_desc, 
        i.i_brand
    FROM 
        RankedSales r
    JOIN 
        item i ON r.ws_item_sk = i.i_item_sk
    WHERE 
        r.rank_profit <= 10
)
SELECT 
    t.i_item_desc AS item_desc,
    t.i_brand AS brand,
    SUM(ws.ws_quantity) AS total_sales_quantity,
    AVG(ws.ws_net_profit) AS avg_item_profit,
    COUNT(DISTINCT ws.ws_order_number) AS unique_orders
FROM 
    TopProfitableItems t
JOIN 
    web_sales ws ON t.ws_item_sk = ws.ws_item_sk
GROUP BY 
    t.i_item_desc, t.i_brand
ORDER BY 
    total_sales_quantity DESC;
