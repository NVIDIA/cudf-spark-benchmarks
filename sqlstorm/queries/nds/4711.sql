
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq = 10 LIMIT 1) 
        AND (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq = 12 LIMIT 1)
),
HighProfitItems AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_quantity) AS total_quantity,
        SUM(rs.ws_net_profit) AS total_net_profit
    FROM 
        RankedSales rs
    WHERE 
        rs.rn <= 10
    GROUP BY 
        rs.ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    hpi.total_quantity,
    hpi.total_net_profit,
    COALESCE(SUM(ss.ss_quantity), 0) AS store_sales_quantity,
    COALESCE(SUM(ws.ws_quantity), 0) AS web_sales_quantity
FROM 
    HighProfitItems hpi
JOIN 
    item i ON hpi.ws_item_sk = i.i_item_sk
LEFT JOIN 
    store_sales ss ON i.i_item_sk = ss.ss_item_sk 
LEFT JOIN 
    web_sales ws ON i.i_item_sk = ws.ws_item_sk 
WHERE 
    i.i_current_price > 50.00
GROUP BY 
    i.i_item_id, i.i_item_desc, hpi.total_quantity, hpi.total_net_profit
HAVING 
    SUM(ws.ws_quantity) > 100 OR hpi.total_net_profit > 1000
ORDER BY 
    hpi.total_net_profit DESC;
