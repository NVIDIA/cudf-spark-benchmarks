
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023) 
    GROUP BY 
        ws.ws_item_sk, ws.ws_sold_date_sk
),
TopItems AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_profit
    FROM 
        RankedSales rs
    WHERE 
        rs.profit_rank <= 5
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price
    FROM 
        item i
    JOIN 
        TopItems ti ON i.i_item_sk = ti.ws_item_sk
)
SELECT 
    i.i_item_desc AS item_desc,
    i.i_current_price AS current_price,
    COALESCE(total_sales.total_quantity, 0) AS total_quantity,
    COALESCE(total_sales.total_profit, 0) AS total_profit,
    CASE 
        WHEN i.i_current_price > 0 THEN ROUND(COALESCE(total_sales.total_profit, 0) / i.i_current_price, 2) 
        ELSE NULL 
    END AS profit_margin
FROM 
    ItemDetails i
LEFT JOIN (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
) AS total_sales ON i.i_item_sk = total_sales.ws_item_sk
ORDER BY 
    total_profit DESC;
