
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2021) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2021)
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        ri.ws_item_sk,
        ri.total_sold,
        ri.total_profit,
        i.i_item_desc,
        i.i_current_price,
        r.r_reason_desc
    FROM 
        RankedSales ri
    JOIN 
        item i ON ri.ws_item_sk = i.i_item_sk
    LEFT JOIN 
        store_returns sr ON ri.ws_item_sk = sr.sr_item_sk
    LEFT JOIN 
        reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE 
        ri.rn = 1
)
SELECT 
    ti.*,
    CASE 
        WHEN ti.total_profit > 1000 THEN 'High'
        WHEN ti.total_profit BETWEEN 500 AND 1000 THEN 'Moderate'
        ELSE 'Low'
    END AS profit_category
FROM 
    TopItems ti
ORDER BY 
    ti.total_sold DESC
LIMIT 10;
