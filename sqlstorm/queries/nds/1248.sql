
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
HighProfitSales AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_net_profit) AS total_net_profit,
        SUM(rs.ws_quantity) AS total_quantity
    FROM 
        RankedSales rs
    WHERE 
        rs.rank <= 10
    GROUP BY 
        rs.ws_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price
    FROM 
        item i
),
FinalResult AS (
    SELECT 
        id.i_item_id,
        id.i_item_desc,
        id.i_current_price,
        COALESCE(hps.total_net_profit, 0) AS total_net_profit,
        COALESCE(hps.total_quantity, 0) AS total_quantity,
        CASE 
            WHEN hps.total_net_profit IS NOT NULL THEN 'High Profit'
            ELSE 'Low Profit'
        END AS profit_category
    FROM 
        ItemDetails id
    LEFT JOIN 
        HighProfitSales hps ON id.i_item_sk = hps.ws_item_sk
)
SELECT 
    fr.i_item_id,
    fr.i_item_desc,
    fr.i_current_price,
    fr.total_net_profit,
    fr.total_quantity,
    fr.profit_category
FROM 
    FinalResult fr
ORDER BY 
    fr.total_net_profit DESC,
    fr.total_quantity DESC
LIMIT 50;
