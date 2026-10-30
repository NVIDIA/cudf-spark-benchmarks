
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2001 AND 
        dd.d_moy IN (11, 12) 
    GROUP BY 
        ws.ws_item_sk
),
TopSellingItems AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        RankedSales.total_quantity,
        RankedSales.total_profit
    FROM 
        RankedSales
    JOIN 
        item ON RankedSales.ws_item_sk = item.i_item_sk
    WHERE 
        RankedSales.rn <= 10
)
SELECT 
    ts.i_item_id AS item_id,
    ts.i_item_desc AS item_desc,
    ts.total_quantity,
    ts.total_profit,
    CASE 
        WHEN ts.total_profit > 1000 THEN 'High'
        WHEN ts.total_profit > 500 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM 
    TopSellingItems ts
ORDER BY 
    ts.total_profit DESC;
