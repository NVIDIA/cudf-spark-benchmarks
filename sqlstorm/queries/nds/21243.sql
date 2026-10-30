
WITH CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM store_returns
    GROUP BY sr_returned_date_sk, sr_item_sk
),
WebSalesAnalysis AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sold_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        MAX(ws_net_paid_inc_ship_tax) AS max_net_paid_inc_ship_tax
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
CombinedReturns AS (
    SELECT 
        cr.sr_item_sk,
        cr.total_returns,
        cr.total_return_amount,
        wa.total_sold_quantity,
        wa.total_net_profit,
        wa.max_net_paid_inc_ship_tax
    FROM CustomerReturns cr
    LEFT JOIN WebSalesAnalysis wa ON cr.sr_item_sk = wa.ws_item_sk
)
SELECT 
    CASE 
        WHEN total_returns IS NULL THEN 'No Returns' 
        WHEN total_returns >= 5 THEN 'Frequent Returner'
        ELSE 'Occasional Returner' 
    END AS return_category,
    COALESCE(total_return_amount, 0) AS total_return_amount,
    COALESCE(total_sold_quantity, 0) AS total_sold_quantity,
    COALESCE(total_net_profit, 0) AS total_net_profit,
    COALESCE(max_net_paid_inc_ship_tax, 0) AS max_net_paid_inc_ship_tax,
    CASE 
        WHEN total_return_amount > total_net_profit THEN 'Loss'
        WHEN total_return_amount = total_net_profit THEN 'Break-even'
        ELSE 'Profit'
    END AS profitability_status
FROM CombinedReturns
WHERE 
    (total_sold_quantity > 10 OR total_returns IS NULL) 
    AND (total_return_amount IS NOT NULL)

UNION ALL

SELECT 
    'Aggregate' AS return_category,
    SUM(COALESCE(total_return_amount, 0)) AS total_return_amount,
    SUM(COALESCE(total_sold_quantity, 0)) AS total_sold_quantity,
    SUM(COALESCE(total_net_profit, 0)) AS total_net_profit,
    MAX(COALESCE(max_net_paid_inc_ship_tax, 0)) AS max_net_paid_inc_ship_tax,
    CASE 
        WHEN SUM(COALESCE(total_return_amount, 0)) > SUM(COALESCE(total_net_profit, 0)) THEN 'Loss'
        WHEN SUM(COALESCE(total_return_amount, 0)) = SUM(COALESCE(total_net_profit, 0)) THEN 'Break-even'
        ELSE 'Profit'
    END AS profitability_status
FROM CombinedReturns;
