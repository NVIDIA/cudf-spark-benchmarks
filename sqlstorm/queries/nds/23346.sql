
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        SUM(ws_net_profit) OVER (PARTITION BY ws_item_sk ORDER BY ws_ship_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_ship_date_sk DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_net_profit IS NOT NULL
    AND ws_sales_price > 10
),
FilteredReturns AS (
    SELECT 
        cr_item_sk,
        COUNT(DISTINCT cr_order_number) AS return_count,
        SUM(cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns
    WHERE 
        cr_return_quantity > 0
    GROUP BY 
        cr_item_sk
),
FinalMetrics AS (
    SELECT 
        r.ws_item_sk,
        r.ws_sales_price,
        r.ws_quantity,
        COALESCE(f.return_count, 0) AS return_count,
        COALESCE(f.total_return_amount, 0) AS total_return_amount,
        r.total_net_profit
    FROM 
        RankedSales r
    LEFT JOIN 
        FilteredReturns f ON r.ws_item_sk = f.cr_item_sk
    WHERE 
        r.rn = 1
)
SELECT 
    fm.ws_item_sk,
    fm.ws_sales_price,
    fm.ws_quantity,
    (fm.total_net_profit - fm.total_return_amount) AS net_profit_after_returns,
    CASE 
        WHEN fm.return_count > 0 THEN 'High' 
        ELSE 'Low' 
    END AS return_indicator,
    ROW_NUMBER() OVER (ORDER BY (fm.total_net_profit - fm.total_return_amount) DESC) AS sales_rank
FROM 
    FinalMetrics fm
WHERE 
    (fm.total_net_profit - fm.total_return_amount > 0 OR fm.return_count IS NULL)
AND 
    fm.ws_sales_price IS NOT NULL
ORDER BY 
    sales_rank
LIMIT 100;
