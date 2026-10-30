
WITH ranked_sales AS (
    SELECT 
        ws.ws_order_number, 
        ws.ws_item_sk, 
        ws.ws_ship_mode_sk, 
        ws.ws_net_paid,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS item_rank
    FROM web_sales ws
    WHERE ws.ws_net_paid > 0 
      AND ws.ws_ship_mode_sk IN (SELECT sm.sm_ship_mode_sk FROM ship_mode sm WHERE sm.sm_code IS NOT NULL)
),
aggregated_returns AS (
    SELECT 
        sr_item_sk, 
        SUM(sr_return_quantity) AS total_returns, 
        AVG(sr_return_amt) AS avg_return_amt
    FROM store_returns
    WHERE sr_return_quantity IS NOT NULL
    GROUP BY sr_item_sk
),
filtered_sales AS (
    SELECT 
        rs.ws_order_number,
        rs.ws_item_sk,
        rs.ws_net_paid,
        ar.total_returns,
        ar.avg_return_amt
    FROM ranked_sales rs
    LEFT JOIN aggregated_returns ar ON rs.ws_item_sk = ar.sr_item_sk
    WHERE rs.item_rank = 1
      AND (ar.total_returns IS NULL OR ar.total_returns < 5)
)
SELECT 
    fs.ws_order_number,
    fs.ws_item_sk,
    fs.ws_net_paid,
    COALESCE(fs.total_returns, 0) AS total_returns,
    COALESCE(fs.avg_return_amt, 0.00) AS avg_return_amt,
    CASE 
        WHEN fs.ws_net_paid > 100 THEN 'High Value'
        WHEN fs.ws_net_paid BETWEEN 50 AND 100 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS value_category
FROM filtered_sales fs
WHERE fs.ws_net_paid IS NOT NULL
ORDER BY fs.ws_net_paid DESC, fs.ws_order_number ASC
LIMIT 20 OFFSET 10;
