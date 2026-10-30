
WITH  SalesCTE AS (
    SELECT ws_sold_date_sk, ws_item_sk, ws_quantity, ws_sales_price, ws_net_profit,
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
),
CustomerReturns AS (
    SELECT sr_item_sk, SUM(sr_return_quantity) AS total_returns
    FROM store_returns
    GROUP BY sr_item_sk
),
ItemPromotion AS (
    SELECT i_item_sk, i_item_desc, p_discount_active
    FROM item
    LEFT JOIN promotion ON i_item_sk = p_item_sk
    WHERE p_start_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
      AND (p_end_date_sk IS NULL OR p_end_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023))
),
AggregatedSales AS (
    SELECT s.ws_item_sk,
           SUM(ws_sales_price) AS total_sales,
           SUM(ws_quantity) AS total_quantity,
           MAX(ws_net_profit) AS max_net_profit
    FROM web_sales s
    INNER JOIN date_dim d ON s.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY s.ws_item_sk
)
SELECT a.ws_item_sk, i.i_item_desc, a.total_sales, a.total_quantity, a.max_net_profit,
       COALESCE(cr.total_returns, 0) AS total_returns,
       CASE WHEN ip.p_discount_active = 'Y' THEN 'Yes' ELSE 'No' END AS promotional_item
FROM AggregatedSales a
JOIN item i ON a.ws_item_sk = i.i_item_sk
LEFT JOIN CustomerReturns cr ON a.ws_item_sk = cr.sr_item_sk
LEFT JOIN ItemPromotion ip ON a.ws_item_sk = ip.i_item_sk
WHERE a.total_sales > 10000 AND a.total_quantity > 50
ORDER BY total_sales DESC, total_quantity DESC
LIMIT 10;
