
WITH  sales_summary AS (
    SELECT ws_item_sk,
           SUM(ws_sales_price) AS total_sales,
           COUNT(ws_order_number) AS total_orders,
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2452453 AND 2456784 
    GROUP BY ws_item_sk
),
top_sales AS (
    SELECT ws_item_sk AS ss_item_sk,
           total_sales,
           total_orders
    FROM sales_summary
    WHERE sales_rank <= 10
),
customer_returns AS (
    SELECT cr_item_sk,
           SUM(cr_return_quantity) AS total_returns
    FROM catalog_returns
    GROUP BY cr_item_sk
)
SELECT i.i_item_id,
       i.i_item_desc,
       COALESCE(ts.total_sales, 0) AS total_sales,
       COALESCE(ts.total_orders, 0) AS total_orders,
       COALESCE(cr.total_returns, 0) AS total_returns,
       (COALESCE(ts.total_sales, 0) - COALESCE(cr.total_returns, 0)) AS net_sales,
       CASE
           WHEN COALESCE(ts.total_sales, 0) = 0 THEN 0
           ELSE (COALESCE(cr.total_returns, 0) * 100.0) / NULLIF(COALESCE(ts.total_sales, 0), 0)
       END AS return_rate
FROM item AS i
LEFT JOIN top_sales AS ts ON i.i_item_sk = ts.ss_item_sk
LEFT JOIN customer_returns AS cr ON i.i_item_sk = cr.cr_item_sk
ORDER BY net_sales DESC
LIMIT 20;
