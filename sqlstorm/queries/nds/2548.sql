WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        SUM(ws_ext_sales_price) AS total_sales_amount,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS item_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2459015 AND 2459316 
    GROUP BY ws_item_sk
),
CustomerReturns AS (
    SELECT 
        wr_item_sk,
        COUNT(wr_return_quantity) AS total_returns,
        SUM(wr_net_loss) AS total_return_loss
    FROM web_returns
    GROUP BY wr_item_sk
),
ItemDetails AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        i_current_price,
        i_category
    FROM item
    WHERE i_rec_start_date <= cast('2002-10-01' as date) AND (i_rec_end_date IS NULL OR i_rec_end_date > cast('2002-10-01' as date))
),
FinalReport AS (
    SELECT 
        s.item_sk,
        id.i_item_desc,
        id.i_current_price,
        COALESCE(sd.total_quantity, 0) AS total_quantity_sold,
        COALESCE(sd.total_net_profit, 0) AS total_net_profit,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_loss, 0) AS total_return_loss,
        CASE 
            WHEN COALESCE(sd.total_quantity, 0) = 0 THEN NULL 
            ELSE (COALESCE(cr.total_returns, 0) * 1.0 / COALESCE(sd.total_quantity, 1)) * 100 
        END AS return_percentage
    FROM (
        SELECT DISTINCT ws_item_sk AS item_sk
        FROM web_sales
    ) s
    LEFT JOIN SalesData sd ON s.item_sk = sd.ws_item_sk
    LEFT JOIN CustomerReturns cr ON s.item_sk = cr.wr_item_sk
    JOIN ItemDetails id ON s.item_sk = id.i_item_sk
)
SELECT 
    f.item_sk,
    f.i_item_desc,
    f.i_current_price,
    f.total_quantity_sold,
    f.total_net_profit,
    f.total_returns,
    f.total_return_loss,
    f.return_percentage
FROM FinalReport f
WHERE f.return_percentage IS NOT NULL 
ORDER BY f.return_percentage DESC
LIMIT 10;