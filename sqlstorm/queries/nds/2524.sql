
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rnk
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
),
StoreReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        COUNT(sr_returned_date_sk) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
ItemStats AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        COALESCE(r.total_returns, 0) AS total_returns,
        COALESCE(r.return_count, 0) AS return_count,
        SUM(s.ws_net_profit) AS total_net_profit
    FROM 
        item i
    LEFT JOIN 
        RankedSales s ON i.i_item_sk = s.ws_item_sk
    LEFT JOIN 
        StoreReturns r ON i.i_item_sk = r.sr_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc, r.total_returns, r.return_count
)
SELECT 
    i.i_item_desc,
    i.total_returns,
    i.return_count,
    i.total_net_profit,
    CASE 
        WHEN i.return_count > 0 THEN 'Returned'
        ELSE 'Non-returned'
    END AS return_status
FROM 
    ItemStats i
WHERE 
    i.total_net_profit > (SELECT AVG(total_net_profit) FROM ItemStats)
ORDER BY 
    i.total_net_profit DESC
LIMIT 10;
