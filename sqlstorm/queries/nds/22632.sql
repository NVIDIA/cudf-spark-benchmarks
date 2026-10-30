
WITH RecursiveSales AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_order_number,
        ws.ws_sales_price, 
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_order_number DESC) AS sales_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 100 AND 200
),
FilteredReturns AS (
    SELECT 
        sr_item_sk, 
        SUM(sr_return_quantity) AS total_returns, 
        AVG(sr_return_amt) AS avg_return_amt
    FROM store_returns
    GROUP BY sr_item_sk
    HAVING SUM(sr_return_quantity) > 0
),
MaxProfit AS (
    SELECT
        ws_item_sk,
        MAX(ws_net_profit) AS max_net_profit
    FROM RecursiveSales
    GROUP BY ws_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(sales.total_quantity, 0) AS total_quantity_sold,
    COALESCE(returns.total_returns, 0) AS total_returns,
    COALESCE(returns.avg_return_amt, 0) AS avg_return_value,
    profit.max_net_profit
FROM item i
LEFT JOIN (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_quantity) AS total_quantity
    FROM RecursiveSales rs
    GROUP BY rs.ws_item_sk
) sales ON i.i_item_sk = sales.ws_item_sk
LEFT JOIN FilteredReturns returns ON i.i_item_sk = returns.sr_item_sk
LEFT JOIN MaxProfit profit ON i.i_item_sk = profit.ws_item_sk
WHERE (sales.total_quantity IS NOT NULL OR returns.total_returns IS NOT NULL)
AND (profit.max_net_profit IS NOT NULL OR (returns.total_returns IS NULL AND profit.max_net_profit IS NULL))
ORDER BY profit.max_net_profit DESC, total_quantity_sold DESC
LIMIT 100;
