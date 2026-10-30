
WITH RankedSales AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        ws_order_number,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_paid DESC) as rnk
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 20220101 AND 20221231
), TotalSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_paid) AS total_net_paid
    FROM web_sales
    GROUP BY ws_item_sk
    HAVING SUM(ws_net_paid) > 10000
), LeftOverItems AS (
    SELECT 
        i_item_sk,
        i_item_desc
    FROM item
    WHERE i_current_price IS NOT NULL
), CategorizedReturns AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        COUNT(*) AS return_count,
        CASE 
            WHEN SUM(sr_return_quantity) > 10 THEN 'High'
            WHEN SUM(sr_return_quantity) BETWEEN 5 AND 10 THEN 'Medium'
            ELSE 'Low'
        END AS return_category
    FROM store_returns
    GROUP BY sr_item_sk
), CombinedReturns AS (
    SELECT
        wr.wr_item_sk,
        COALESCE(sr.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(sr.return_count, 0) AS return_count,
        sr.return_category
    FROM web_returns wr
    LEFT JOIN CategorizedReturns sr ON wr.wr_item_sk = sr.sr_item_sk
), FilteredItems AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc
    FROM item i
    LEFT JOIN CombinedReturns cr ON i.i_item_sk = cr.wr_item_sk
    WHERE cr.return_count < 5 OR cr.return_count IS NULL
)
SELECT
    ri.i_item_sk,
    ri.i_item_desc,
    COALESCE(ts.total_net_paid, 0) AS total_sales,
    cr.return_category,
    MAX(CASE WHEN rs.rnk = 1 THEN rs.ws_net_paid ELSE NULL END) AS max_net_paid
FROM RankedSales rs
FULL OUTER JOIN FilteredItems ri ON rs.ws_item_sk = ri.i_item_sk
FULL OUTER JOIN TotalSales ts ON ri.i_item_sk = ts.ws_item_sk
LEFT JOIN CombinedReturns cr ON ri.i_item_sk = cr.wr_item_sk
GROUP BY
    ri.i_item_sk,
    ri.i_item_desc,
    ts.total_net_paid,
    cr.return_category
ORDER BY total_sales DESC, max_net_paid DESC
LIMIT 50;
