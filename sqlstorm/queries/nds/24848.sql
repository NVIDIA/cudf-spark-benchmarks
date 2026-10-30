
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year IS NOT NULL
      AND ws.ws_ext_sales_price > 0
),
Returns AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM store_returns
    WHERE sr_return_quantity > 0
    GROUP BY sr_item_sk
),
TopItems AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_ext_sales_price,
        rs.ws_net_profit,
        COALESCE(r.total_returns, 0) AS total_returns,
        r.return_count
    FROM RankedSales rs
    LEFT JOIN Returns r ON rs.ws_item_sk = r.sr_item_sk
    WHERE rs.rn = 1
)
SELECT 
    ti.ws_item_sk,
    ti.ws_order_number,
    ti.ws_ext_sales_price,
    ti.ws_net_profit,
    CASE 
        WHEN ti.return_count > 0 THEN 'Returned'
        WHEN ti.total_returns > 0 AND ti.ws_net_profit > 100 THEN 'High Profit with Returns'
        ELSE 'No Returns'
    END AS return_status,
    CASE 
        WHEN ti.ws_ext_sales_price < 0 THEN 'Negative Price'
        WHEN ti.ws_ext_sales_price IS NULL THEN 'Null Price'
        ELSE 'Valid Price'
    END AS price_status
FROM TopItems ti
WHERE (ti.total_returns > 10 OR (ti.ws_net_profit > 500 AND ti.return_count IS NOT NULL))
ORDER BY ti.ws_net_profit DESC, ti.total_returns ASC
LIMIT 100;
