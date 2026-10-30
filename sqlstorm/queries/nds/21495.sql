
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_net_profit IS NOT NULL
),
AggregatedReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount,
        SUM(sr_return_tax) AS total_return_tax
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
ReturnMetrics AS (
    SELECT 
        a.ws_item_sk,
        a.ws_order_number,
        a.ws_net_profit,
        COALESCE(b.total_returns, 0) AS total_returns,
        COALESCE(b.total_returned_amount, 0) AS total_returned_amount,
        COALESCE(b.total_return_tax, 0) AS total_return_tax
    FROM 
        RankedSales a
    LEFT JOIN 
        AggregatedReturns b ON a.ws_item_sk = b.sr_item_sk
    WHERE 
        a.profit_rank = 1
),
FinalMetrics AS (
    SELECT 
        r.ws_item_sk,
        r.ws_order_number,
        r.ws_net_profit,
        CASE 
            WHEN r.total_returns > 0 THEN r.ws_net_profit - r.total_returned_amount 
            ELSE r.ws_net_profit 
        END AS adjusted_net_profit,
        CASE 
            WHEN r.total_return_tax IS NOT NULL THEN r.total_return_tax / NULLIF(r.ws_net_profit, 0) 
            ELSE 0 
        END AS return_tax_ratio
    FROM 
        ReturnMetrics r
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    f.adjusted_net_profit,
    f.return_tax_ratio,
    CASE 
        WHEN f.return_tax_ratio > 0.1 THEN 'High Tax Ratio'
        WHEN f.return_tax_ratio <= 0.1 AND f.return_tax_ratio > 0 THEN 'Moderate Tax Ratio'
        ELSE 'No Tax'
    END AS tax_ratio_category
FROM 
    FinalMetrics f
JOIN 
    item i ON f.ws_item_sk = i.i_item_sk
WHERE 
    f.adjusted_net_profit > (
        SELECT AVG(adjusted_net_profit) FROM FinalMetrics
    )
ORDER BY 
    f.adjusted_net_profit DESC
LIMIT 20;
