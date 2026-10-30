
WITH  RankedReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_quantity) DESC) AS rank
    FROM store_returns
    GROUP BY sr_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        COALESCE(i.i_current_price, 0) AS current_price,
        COALESCE(i.i_wholesale_cost, 0) AS wholesale_cost,
        CASE 
            WHEN i.i_current_price > 0 THEN (i.i_current_price - i.i_wholesale_cost) / i.i_current_price * 100
            ELSE NULL
        END AS profit_margin
    FROM item i
),
HighReturnItems AS (
    SELECT 
        r.returning_item,
        r.total_returns,
        d.i_item_desc,
        d.current_price,
        d.profit_margin
    FROM (
        SELECT 
            rr.sr_item_sk AS returning_item,
            rr.total_returns,
            ROW_NUMBER() OVER (ORDER BY rr.total_returns DESC) AS return_rank
        FROM RankedReturns rr
        WHERE rr.rank = 1
    ) r
    JOIN ItemDetails d ON r.returning_item = d.i_item_sk
    WHERE r.total_returns > 5
)
SELECT 
    hri.returning_item,
    hri.total_returns,
    hri.i_item_desc,
    hri.current_price,
    hri.profit_margin,
    CASE 
        WHEN hri.profit_margin IS NULL THEN 'Profit Margin Unavailable'
        WHEN hri.profit_margin < 20 THEN 'Low Profit Margin'
        WHEN hri.profit_margin >= 20 AND hri.profit_margin < 50 THEN 'Moderate Profit Margin'
        ELSE 'High Profit Margin'
    END AS profit_margin_category
FROM HighReturnItems hri
LEFT JOIN (
    SELECT 
        ws_item_sk,
        SUM(ws_net_paid) AS total_sales
    FROM web_sales
    WHERE ws_ship_date_sk IS NOT NULL
    GROUP BY ws_item_sk
) ws ON hri.returning_item = ws.ws_item_sk
WHERE (hri.total_returns > COALESCE(ws.total_sales, 0) OR ws.total_sales IS NULL)
ORDER BY hri.total_returns DESC
LIMIT 10;
