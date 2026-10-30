
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
TopSellingItems AS (
    SELECT 
        ws_item_sk,
        SUM(total_quantity) AS cumulative_quantity,
        SUM(total_net_profit) AS cumulative_net_profit
    FROM 
        RankedSales
    WHERE 
        profit_rank <= 5
    GROUP BY 
        ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    tsi.cumulative_quantity,
    tsi.cumulative_net_profit
FROM 
    TopSellingItems tsi
JOIN 
    item i ON tsi.ws_item_sk = i.i_item_sk
ORDER BY 
    tsi.cumulative_net_profit DESC;
