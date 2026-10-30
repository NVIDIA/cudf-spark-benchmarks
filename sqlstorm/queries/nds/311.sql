
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_ship_date_sk,
        ws.ws_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
HighProfitItems AS (
    SELECT 
        ri.ws_item_sk,
        SUM(ri.ws_net_profit) AS total_net_profit
    FROM 
        RankedSales ri
    WHERE 
        ri.profit_rank <= 5
    GROUP BY 
        ri.ws_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        ip.total_net_profit
    FROM 
        item i
    LEFT JOIN 
        HighProfitItems ip ON i.i_item_sk = ip.ws_item_sk
)
SELECT 
    id.i_item_id,
    id.i_product_name,
    COALESCE(id.total_net_profit, 0) AS total_net_profit,
    ROUND(id.i_current_price * 1.1, 2) AS inflated_price,
    CASE 
        WHEN id.total_net_profit IS NOT NULL THEN 'Profitable'
        ELSE 'Not Profitable'
    END AS profit_status
FROM 
    ItemDetails id
ORDER BY 
    total_net_profit DESC
LIMIT 10;
