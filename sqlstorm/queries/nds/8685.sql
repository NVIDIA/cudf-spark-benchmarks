
WITH RankedSales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS rank_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_profit
    FROM 
        web_sales ws 
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk 
    WHERE 
        dd.d_year = 2023 
        AND dd.d_month_seq BETWEEN 1 AND 6 
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
TopProducts AS (
    SELECT 
        rs.ws_item_sk,
        MIN(rs.rank_quantity) AS min_rank_quantity,
        MIN(rs.rank_profit) AS min_rank_profit
    FROM 
        RankedSales rs
    WHERE 
        rs.rank_quantity <= 10 OR rs.rank_profit <= 10
    GROUP BY 
        rs.ws_item_sk
)
SELECT 
    i.i_item_desc,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    SUM(ws.ws_net_profit) AS total_net_profit
FROM 
    web_sales ws
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
JOIN 
    TopProducts tp ON i.i_item_sk = tp.ws_item_sk
GROUP BY 
    i.i_item_desc
ORDER BY 
    total_net_profit DESC
LIMIT 10;
