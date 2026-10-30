
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) as profit_rank,
        COALESCE(NULLIF(ws.ws_net_profit, 0), NULL) as adjusted_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
TopProfitableItems AS (
    SELECT 
        item.i_item_id,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.adjusted_profit) AS total_adjusted_profit
    FROM 
        SalesData sd
    JOIN 
        item ON sd.ws_item_sk = item.i_item_sk
    WHERE 
        sd.profit_rank <= 5
    GROUP BY 
        item.i_item_id
)
SELECT 
    tpi.i_item_id,
    tpi.total_quantity,
    tpi.total_adjusted_profit,
    CASE 
        WHEN tpi.total_adjusted_profit IS NULL THEN 'No Profit'
        WHEN tpi.total_adjusted_profit > 1000 THEN 'High Profit'
        ELSE 'Low Profit'
    END AS Profit_Category
FROM 
    TopProfitableItems tpi
ORDER BY 
    tpi.total_adjusted_profit DESC
LIMIT 10;
