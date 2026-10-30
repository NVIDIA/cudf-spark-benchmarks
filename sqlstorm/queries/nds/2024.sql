
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rnk
    FROM web_sales
    WHERE ws_ship_date_sk BETWEEN 2450000 AND 2455000
    GROUP BY ws_item_sk
),
PopularItems AS (
    SELECT 
        rs.ws_item_sk,
        i.i_item_desc,
        i.i_category,
        rs.total_sales
    FROM RankedSales rs
    JOIN item i ON rs.ws_item_sk = i.i_item_sk
    WHERE rs.rnk <= 5
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_return_amt
    FROM store_returns
    GROUP BY sr_item_sk
)
SELECT 
    pi.i_item_desc,
    pi.i_category,
    pi.total_sales,
    COALESCE(cr.return_count, 0) AS return_count,
    COALESCE(cr.total_return_amt, 0) AS total_return_amt,
    (pi.total_sales - COALESCE(cr.total_return_amt, 0)) AS net_profit_margin
FROM PopularItems pi
LEFT JOIN CustomerReturns cr ON pi.ws_item_sk = cr.sr_item_sk
ORDER BY net_profit_margin DESC
LIMIT 10;
