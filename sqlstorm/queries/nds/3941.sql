
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_order_number DESC) AS rn
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2400 AND 2425
),
customer_returns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM web_returns wr
    GROUP BY wr.wr_item_sk
),
inventory_data AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory inv
    GROUP BY inv.inv_item_sk
)
SELECT 
    s.ws_item_sk,
    s.ws_order_number,
    s.ws_sales_price,
    s.ws_ext_discount_amt,
    s.ws_net_profit,
    COALESCE(cr.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(cr.total_return_amt, 0) AS total_return_amt,
    COALESCE(i.total_quantity_on_hand, 0) AS total_quantity_on_hand
FROM sales_data s
LEFT JOIN customer_returns cr ON s.ws_item_sk = cr.wr_item_sk
LEFT JOIN inventory_data i ON s.ws_item_sk = i.inv_item_sk
WHERE s.rn = 1 
  AND s.ws_net_profit > 0
  AND (cr.total_return_quantity IS NULL OR cr.total_return_quantity < 10)
ORDER BY s.ws_item_sk, s.ws_order_number;
