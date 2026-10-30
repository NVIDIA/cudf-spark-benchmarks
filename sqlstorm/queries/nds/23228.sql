
WITH RecursiveSales AS (
    SELECT ws_item_sk, ws_order_number, ws_quantity, ws_net_profit, 
           DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rank_profit
    FROM web_sales
    WHERE ws_net_profit IS NOT NULL
), 
TopWebSales AS (
    SELECT ws_item_sk, SUM(ws_quantity) AS total_quantity, SUM(ws_net_profit) AS total_net_profit
    FROM web_sales
    WHERE ws_sales_price > 0
    GROUP BY ws_item_sk
),
CustomerReturns AS (
    SELECT cr_returning_customer_sk, SUM(cr_return_quantity) AS total_returned
    FROM catalog_returns
    WHERE cr_returned_date_sk IN (
          SELECT d_date_sk FROM date_dim 
          WHERE d_year = 2022 AND d_month_seq IN (6, 7, 8)
    )
    GROUP BY cr_returning_customer_sk
),
AllReturns AS (
    SELECT wr_returning_customer_sk AS customer_sk, SUM(wr_return_quantity) AS total_returned 
    FROM web_returns
    GROUP BY wr_returning_customer_sk
    UNION ALL
    SELECT sr_customer_sk AS customer_sk, SUM(sr_return_quantity) AS total_returned 
    FROM store_returns
    GROUP BY sr_customer_sk
),
AggregatedReturns AS (
    SELECT customer_sk, COALESCE(SUM(total_returned), 0) AS total_returned_per_customer
    FROM AllReturns
    GROUP BY customer_sk
),
FinalSales AS (
    SELECT a.customer_sk, COALESCE(b.total_quantity, 0) AS total_quantity, 
           COALESCE(b.total_net_profit, 0) AS total_net_profit, 
           COALESCE(c.total_returned_per_customer, 0) AS total_returns
    FROM (SELECT DISTINCT c_customer_sk AS customer_sk FROM customer WHERE c_birth_year = 1980) a
    LEFT JOIN TopWebSales b ON a.customer_sk = b.ws_item_sk
    LEFT JOIN AggregatedReturns c ON a.customer_sk = c.customer_sk
)
SELECT customer_sk, total_quantity, total_net_profit, total_returns,
       CASE 
           WHEN total_net_profit = 0 THEN 'No Profit'
           WHEN total_returns > total_quantity THEN 'High Returns'
           ELSE 'Normal'
       END AS profit_status
FROM FinalSales
WHERE (total_net_profit > (SELECT AVG(total_net_profit) FROM FinalSales) OR total_returns IS NOT NULL)
ORDER BY customer_sk, total_net_profit DESC;
