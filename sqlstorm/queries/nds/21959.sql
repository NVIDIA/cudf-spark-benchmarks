
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales
    GROUP BY ws_item_sk
),
HighProfitItems AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        r.r_reason_desc,
        p.p_promo_name,
        rs.total_quantity_sold,
        rs.total_net_profit,
        rs.ws_item_sk
    FROM item i
    JOIN RankedSales rs ON i.i_item_sk = rs.ws_item_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = rs.ws_item_sk
    LEFT JOIN reason r ON r.r_reason_sk = sr.sr_reason_sk
    LEFT JOIN promotion p ON p.p_item_sk = rs.ws_item_sk
    WHERE rs.profit_rank <= 5 AND (r.r_reason_desc IS NOT NULL OR p.p_promo_name IS NOT NULL)
),
FinalAnalytics AS (
    SELECT 
        hpi.i_item_id,
        hpi.i_item_desc,
        COALESCE(hpi.total_quantity_sold, 0) AS total_sold,
        COALESCE(hpi.total_net_profit, 0) AS net_profit,
        CASE 
            WHEN hpi.total_net_profit < 0 THEN 'Loss'
            WHEN hpi.total_net_profit = 0 THEN 'Break Even'
            ELSE 'Profit'
        END AS profit_status
    FROM HighProfitItems hpi
    FULL OUTER JOIN (
        SELECT DISTINCT ws_item_sk
        FROM web_sales
        WHERE ws_sold_date_sk >= 20220000
    ) ws ON hpi.ws_item_sk = ws.ws_item_sk
)
SELECT 
    fa.i_item_id,
    fa.i_item_desc,
    fa.total_sold,
    fa.net_profit,
    fa.profit_status,
    CASE 
        WHEN fa.profit_status = 'Loss' THEN 'Danger Zone'
        ELSE 'Safe Zone'
    END AS risk_assessment,
    CONCAT('Item: ', fa.i_item_id, ' | Profit Status: ', fa.profit_status) AS item_overview
FROM FinalAnalytics fa
ORDER BY fa.net_profit DESC NULLS LAST
LIMIT 10 OFFSET 10;
