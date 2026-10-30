
WITH  SalesSummary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS item_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY ws.ws_item_sk
),
TopSales AS (
    SELECT ss.ws_item_sk, ss.total_net_profit, ss.order_count
    FROM SalesSummary ss
    WHERE ss.item_rank <= 10
),
HighProfitItems AS (
    SELECT i.i_item_sk, i.i_item_desc, t.total_net_profit, t.order_count
    FROM item i
    JOIN TopSales t ON i.i_item_sk = t.ws_item_sk
    WHERE i.i_current_price > 20.00
),
CustomerReturns AS (
    SELECT sr_returned_date_sk, sr_item_sk, SUM(sr_return_quantity) AS total_returned
    FROM store_returns
    GROUP BY sr_returned_date_sk, sr_item_sk
),
FinalJoin AS (
    SELECT 
        hpi.i_item_desc,
        hpi.total_net_profit,
        hpi.order_count,
        COALESCE(cr.total_returned, 0) AS total_returned
    FROM HighProfitItems hpi
    LEFT JOIN CustomerReturns cr ON hpi.i_item_sk = cr.sr_item_sk
)
SELECT 
    f.i_item_desc,
    f.total_net_profit,
    f.order_count,
    f.total_returned,
    CASE 
        WHEN f.total_returned = 0 THEN 'No Returns'
        WHEN f.total_returned < f.order_count THEN 'Some Returns'
        ELSE 'Fully Returned'
    END AS return_status
FROM FinalJoin f
ORDER BY f.total_net_profit DESC;
