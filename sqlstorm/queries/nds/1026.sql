
WITH SalesSummary AS (
    SELECT ws.ws_item_sk,
           SUM(ws.ws_quantity) AS total_quantity,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           SUM(ws.ws_ext_tax) AS total_tax,
           ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.ws_item_sk
),
TopSellingItems AS (
    SELECT ss.ws_item_sk, ss.total_quantity, ss.total_sales, ss.total_tax
    FROM SalesSummary ss
    WHERE ss.rank <= 10
),
CustomerReturns AS (
    SELECT wr.wr_item_sk,
           COUNT(wr.wr_return_quantity) AS return_count,
           SUM(wr.wr_return_amt) AS total_return_amt,
           COALESCE(SUM(wr.wr_return_tax), 0) AS total_return_tax
    FROM web_returns wr
    GROUP BY wr.wr_item_sk
),
FinalReport AS (
    SELECT tsi.ws_item_sk,
           tsi.total_quantity,
           tsi.total_sales,
           tsi.total_tax,
           cr.return_count,
           cr.total_return_amt,
           cr.total_return_tax,
           (tsi.total_sales - COALESCE(cr.total_return_amt, 0)) AS net_sales
    FROM TopSellingItems tsi
    LEFT JOIN CustomerReturns cr ON tsi.ws_item_sk = cr.wr_item_sk
)
SELECT f.ws_item_sk,
       f.total_quantity,
       f.total_sales,
       f.total_tax,
       f.return_count,
       f.total_return_amt,
       f.total_return_tax,
       f.net_sales,
       CASE 
           WHEN f.net_sales > 10000 THEN 'High Performer'
           WHEN f.net_sales BETWEEN 5000 AND 10000 THEN 'Moderate Performer'
           ELSE 'Low Performer'
       END AS performance_category
FROM FinalReport f
ORDER BY f.net_sales DESC;
