
WITH sales_data AS (
    SELECT 
        ws_ship_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws_ship_date_sk ORDER BY SUM(ws_net_profit) DESC) AS item_rank
    FROM web_sales
    GROUP BY ws_ship_date_sk, ws_item_sk
),
top_items AS (
    SELECT 
        sd.ws_ship_date_sk,
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_net_profit
    FROM sales_data sd
    WHERE sd.item_rank <= 10
),
customer_returns AS (
    SELECT 
        wr_returned_date_sk,
        wr_item_sk,
        SUM(wr_return_quantity) AS total_return_quantity,
        SUM(wr_return_amt) AS total_return_amt
    FROM web_returns
    GROUP BY wr_returned_date_sk, wr_item_sk
),
return_rate AS (
    SELECT 
        ti.ws_ship_date_sk,
        ti.ws_item_sk,
        CAST(COALESCE(SUM(cr.total_return_quantity), 0) AS DECIMAL) / NULLIF(ti.total_quantity, 0) AS return_ratio
    FROM top_items ti
    LEFT JOIN customer_returns cr ON ti.ws_ship_date_sk = cr.wr_returned_date_sk AND ti.ws_item_sk = cr.wr_item_sk
    GROUP BY ti.ws_ship_date_sk, ti.ws_item_sk, ti.total_quantity
)
SELECT 
    dd.d_date AS sale_date,
    ti.ws_item_sk,
    ti.total_quantity,
    ti.total_net_profit,
    COALESCE(rr.return_ratio, 0) AS return_ratio
FROM date_dim dd
JOIN top_items ti ON dd.d_date_sk = ti.ws_ship_date_sk
LEFT JOIN return_rate rr ON ti.ws_ship_date_sk = rr.ws_ship_date_sk AND ti.ws_item_sk = rr.ws_item_sk
WHERE dd.d_year = 2023
ORDER BY dd.d_date, ti.total_net_profit DESC;
