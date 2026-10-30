WITH RankedSales AS (
    SELECT ws_item_sk,
           ws_sold_date_sk,
           ws_sales_price,
           ws_quantity,
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS ranking
    FROM web_sales
    WHERE ws_sold_date_sk > (SELECT d_date_sk FROM date_dim WHERE d_date = cast('2002-10-01' as date) - INTERVAL '365 days')
),
SalesStats AS (
    SELECT ws_item_sk,
           SUM(ws_sales_price) AS total_sales,
           COUNT(ws_quantity) AS total_transactions,
           AVG(ws_sales_price) AS average_price
    FROM web_sales
    GROUP BY ws_item_sk
),
ItemPerformance AS (
    SELECT i.i_item_sk,
           i.i_item_desc,
           COALESCE(r.total_sales, 0) AS total_sales,
           COALESCE(r.total_transactions, 0) AS total_transactions,
           COALESCE(r.average_price, 0) AS average_price,
           CASE
               WHEN COALESCE(r.total_sales, 0) > 10000 THEN 'High Performer'
               WHEN COALESCE(r.total_sales, 0) BETWEEN 5000 AND 10000 THEN 'Medium Performer'
               ELSE 'Low Performer'
           END AS performance_category
    FROM item i
    LEFT JOIN SalesStats r ON i.i_item_sk = r.ws_item_sk
),
CustomerReturns AS (
    SELECT sr_item_sk,
           COUNT(*) AS return_count,
           SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM store_returns
    WHERE sr_return_quantity > 0
    GROUP BY sr_item_sk
),
FinalResults AS (
    SELECT ip.i_item_sk,
           ip.i_item_desc,
           ip.performance_category,
           COALESCE(cr.return_count, 0) AS return_count,
           COALESCE(cr.total_return_value, 0) AS total_return_value
    FROM ItemPerformance ip
    LEFT JOIN CustomerReturns cr ON ip.i_item_sk = cr.sr_item_sk
)
SELECT f.i_item_sk,
       f.i_item_desc,
       f.performance_category,
       f.return_count,
       f.total_return_value,
       CASE
           WHEN f.return_count > 0 THEN 'Returned'
           ELSE 'Not Returned'
       END AS return_status
FROM FinalResults f
WHERE f.total_return_value > (SELECT AVG(total_return_value) FROM CustomerReturns) 
   OR f.performance_category = 'High Performer'
ORDER BY f.performance_category DESC, f.total_return_value DESC;