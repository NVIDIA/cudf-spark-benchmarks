
WITH  SalesHierarchy AS (
    SELECT ws_sold_date_sk, ws_item_sk, ws_quantity, ws_sales_price, 
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk > (SELECT MAX(d_date_sk) - 30 FROM date_dim)
),
TopSellingItems AS (
    SELECT ws_item_sk, SUM(ws_quantity) AS total_quantity, 
           COUNT(DISTINCT ws_sold_date_sk) AS sale_days
    FROM SalesHierarchy
    WHERE rn <= 5
    GROUP BY ws_item_sk
),
ReturnedItems AS (
    SELECT wr_item_sk, SUM(wr_return_quantity) AS total_returns
    FROM web_returns
    GROUP BY wr_item_sk
),
CombSales AS (
    SELECT tsi.ws_item_sk,
           tsi.total_quantity,
           COALESCE(ri.total_returns, 0) AS total_returns,
           (tsi.total_quantity - COALESCE(ri.total_returns, 0)) AS net_sales
    FROM TopSellingItems tsi
    LEFT JOIN ReturnedItems ri ON tsi.ws_item_sk = ri.wr_item_sk
),
FinalResults AS (
    SELECT ci.i_item_desc, cs.net_sales, ci.i_current_price,
           ci.i_brand, cs.total_quantity, cs.total_returns
    FROM CombSales cs
    JOIN item ci ON cs.ws_item_sk = ci.i_item_sk
    WHERE cs.net_sales > 1000 AND ci.i_current_price < 50
)
SELECT f.i_item_desc, f.net_sales, f.i_current_price,
       CASE 
           WHEN f.total_returns > 0 THEN 'Returned'
           ELSE 'Not Returned'
       END AS return_status
FROM FinalResults f
ORDER BY f.net_sales DESC, f.i_current_price ASC
LIMIT 10;
