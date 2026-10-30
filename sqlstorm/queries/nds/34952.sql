
WITH  SalesCTE AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number DESC) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
TopSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_net_profit) AS total_profit
    FROM SalesCTE
    WHERE rn = 1
    GROUP BY ws_item_sk
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM store_returns
    GROUP BY sr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(ts.total_profit, 0) AS total_profit,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN COALESCE(ts.total_profit, 0) > COALESCE(cr.total_return_amount, 0) THEN 'Profitable'
        ELSE 'Not Profitable'
    END AS profitability_status
FROM item i
LEFT JOIN TopSales ts ON i.i_item_sk = ts.ws_item_sk
LEFT JOIN CustomerReturns cr ON i.i_item_sk = cr.sr_item_sk
WHERE (i.i_current_price IS NOT NULL AND i.i_current_price > 0)
  AND (ts.total_profit IS NULL OR cr.total_return_amount IS NULL OR ts.total_profit > cr.total_return_amount)
ORDER BY total_profit DESC, total_returns ASC;
