WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_rec_start_date <= cast('2002-10-01' as date) AND 
        (i.i_rec_end_date IS NULL OR i.i_rec_end_date > cast('2002-10-01' as date))
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number
),
TopSellingItems AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity_sold,
        rs.total_net_profit,
        ROW_NUMBER() OVER (ORDER BY rs.total_net_profit DESC) AS rank_by_profit
    FROM 
        RankedSales rs
    WHERE 
        rs.rank = 1
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    tsi.total_quantity_sold,
    tsi.total_net_profit
FROM 
    TopSellingItems tsi
JOIN 
    item i ON tsi.ws_item_sk = i.i_item_sk
WHERE 
    tsi.rank_by_profit <= 10
ORDER BY 
    tsi.total_net_profit DESC;