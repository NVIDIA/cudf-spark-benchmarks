
WITH  customer_returns AS (
    SELECT cr_returning_customer_sk, cr_item_sk, 
           SUM(cr_return_quantity) AS total_returned
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk, cr_item_sk
),
sales_summary AS (
    SELECT ws_ship_customer_sk, ws_item_sk,
           SUM(ws_quantity) AS total_sold,
           SUM(ws_net_profit) AS total_profit
    FROM web_sales
    GROUP BY ws_ship_customer_sk, ws_item_sk
),
combined_summary AS (
    SELECT cs.cr_returning_customer_sk,
           cs.cr_item_sk,
           COALESCE(cs.total_returned, 0) AS total_returned,
           COALESCE(ss.total_sold, 0) AS total_sold,
           (COALESCE(ss.total_profit, 0) - COALESCE(cs.total_returned, 0)) AS net_gain
    FROM customer_returns cs
    FULL OUTER JOIN sales_summary ss ON cs.cr_returning_customer_sk = ss.ws_ship_customer_sk 
                                      AND cs.cr_item_sk = ss.ws_item_sk
),
final_summary AS (
    SELECT cr.cr_returning_customer_sk,
           cr.cr_item_sk,
           cr.total_returned,
           cr.total_sold,
           cr.net_gain,
           RANK() OVER (PARTITION BY cr.cr_returning_customer_sk ORDER BY cr.net_gain DESC) AS rank
    FROM combined_summary cr
    WHERE (cr.total_returned IS NOT NULL OR cr.total_sold IS NOT NULL)
      AND (cr.net_gain > 0 OR cr.total_returned IS NULL OR cr.total_sold IS NULL)
)

SELECT f.cr_returning_customer_sk, 
       f.cr_item_sk,
       f.total_returned,
       f.total_sold,
       f.net_gain,
       CASE 
           WHEN f.rank = 1 THEN 'Top Item'
           WHEN f.rank <= 3 THEN 'Top 3 Item'
           ELSE 'Other Item'
       END AS item_category
FROM final_summary f
WHERE f.rank <= 5 OR (f.total_returned IS NULL AND f.total_sold IS NULL)
ORDER BY f.cr_returning_customer_sk, f.net_gain DESC
;
