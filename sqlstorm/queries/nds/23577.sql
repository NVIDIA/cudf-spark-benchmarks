
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn,
        SUM(ws.ws_net_profit) OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit
    FROM web_sales ws
    WHERE ws.ws_ship_date_sk IS NOT NULL
),
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.cumulative_profit,
        COALESCE((
            SELECT MAX(sr_return_quantity)
            FROM store_returns sr
            WHERE sr.sr_item_sk = rs.ws_item_sk AND sr.sr_ticket_number = rs.ws_order_number
        ), 0) AS max_returned_quantity,
        CASE 
            WHEN rs.cumulative_profit < 0 THEN 'Loss'
            WHEN rs.cumulative_profit > 100 THEN 'Profit Over 100'
            ELSE 'Moderate Profit'
        END AS profit_category
    FROM RankedSales rs
    WHERE rs.rn = 1
),
FinalReport AS (
    SELECT 
        ts.ws_item_sk,
        COUNT(DISTINCT ts.ws_order_number) AS order_count,
        SUM(ts.max_returned_quantity) AS total_returned,
        AVG(ts.cumulative_profit) AS avg_profit,
        MAX(ts.cumulative_profit) AS peak_profit
    FROM TopSales ts
    GROUP BY ts.ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    fr.order_count,
    fr.total_returned,
    fr.avg_profit,
    fr.peak_profit,
    CASE 
        WHEN fr.avg_profit IS NULL THEN 'No Data'
        WHEN fr.avg_profit < 0 THEN 'Negative Average Profit'
        ELSE 'Available Data'
    END AS data_status
FROM inventory inv
JOIN item i ON inv.inv_item_sk = i.i_item_sk
LEFT JOIN FinalReport fr ON i.i_item_sk = fr.ws_item_sk
WHERE inv.inv_quantity_on_hand > (SELECT AVG(inv_quantity_on_hand) FROM inventory) 
      AND (fr.peak_profit IS NULL OR fr.total_returned < 5)
ORDER BY fr.peak_profit DESC NULLS LAST, fr.order_count ASC;
