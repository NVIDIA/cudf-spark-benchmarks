
WITH  sales_cte AS (
    SELECT ws_sold_date_sk, ws_item_sk, SUM(ws_net_profit) AS total_profit, 
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
date_filtered AS (
    SELECT d_year, d_month_seq, d_date, 
           COUNT(DISTINCT ws_order_number) AS total_orders,
           SUM(ws_ext_sales_price) AS total_sales
    FROM date_dim dd
    JOIN web_sales ws ON dd.d_date_sk = ws.ws_sold_date_sk
    WHERE dd.d_year = 2023 AND dd.d_month_seq BETWEEN 1 AND 6
    GROUP BY d_year, d_month_seq, d_date
),
highest_sales AS (
    SELECT ws_item_sk, total_profit
    FROM sales_cte
    WHERE profit_rank = 1
),
return_analysis AS (
    SELECT sr_item_sk, 
           SUM(sr_return_quantity) AS total_returns,
           SUM(sr_return_amt) AS total_return_amount
    FROM store_returns
    GROUP BY sr_item_sk
)
SELECT 
    di.d_year,
    di.d_month_seq,
    di.total_orders,
    di.total_sales,
    hs.total_profit,
    COALESCE(ra.total_returns, 0) AS total_returns,
    COALESCE(ra.total_return_amount, 0) AS total_return_amount,
    (di.total_sales - COALESCE(ra.total_return_amount, 0)) AS net_sales
FROM date_filtered di
LEFT JOIN highest_sales hs ON di.d_month_seq = hs.ws_item_sk
LEFT JOIN return_analysis ra ON hs.ws_item_sk = ra.sr_item_sk
WHERE di.total_sales > (SELECT AVG(total_sales) FROM date_filtered)
ORDER BY di.d_month_seq, net_sales DESC;
