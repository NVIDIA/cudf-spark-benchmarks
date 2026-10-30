
WITH RankedSales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rn
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (
        SELECT MAX(d.d_date_sk) - 30
        FROM date_dim d
        WHERE d.d_date >= '2023-01-01'
    )
),
CustomerReturns AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk, wr.wr_item_sk
),
SalesWithReturns AS (
    SELECT
        r.ws_order_number,
        r.ws_item_sk,
        r.ws_sales_price,
        r.ws_quantity,
        r.ws_net_profit,
        COALESCE(cr.total_returned, 0) AS total_returned,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount
    FROM RankedSales r
    LEFT JOIN CustomerReturns cr ON r.ws_item_sk = cr.wr_item_sk
)
SELECT
    c.c_customer_id,
    s.ws_item_sk,
    s.ws_sales_price,
    s.ws_quantity,
    s.total_returned,
    s.total_return_amount,
    s.ws_net_profit - s.total_return_amount AS net_profit_after_returns,
    (CASE
        WHEN s.ws_quantity > 0 THEN (s.total_returned * 1.0 / s.ws_quantity) * 100
        ELSE 0
    END) AS return_rate_percentage
FROM SalesWithReturns s
JOIN customer c ON c.c_customer_sk = s.ws_order_number
WHERE s.ws_net_profit > 100
AND s.ws_item_sk IN (
    SELECT i.i_item_sk
    FROM item i
    WHERE i.i_current_price > 50
    AND i.i_formulation IS NOT NULL
)
ORDER BY net_profit_after_returns DESC, return_rate_percentage ASC
LIMIT 50;
