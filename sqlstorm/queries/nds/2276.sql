
WITH ranked_sales AS (
    SELECT 
        ws_ship_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank_item
    FROM web_sales
    GROUP BY ws_ship_date_sk, ws_item_sk
),
total_customer_returns AS (
    SELECT
        sr_item_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns
    FROM store_returns
    GROUP BY sr_item_sk
),
item_details AS (
    SELECT
        i_item_sk,
        i_item_desc,
        i_current_price,
        i_category
    FROM item
    LEFT JOIN catalog_sales cs ON i_item_sk = cs.cs_item_sk
    LEFT JOIN inventory inv ON i_item_sk = inv.inv_item_sk
    WHERE inv.inv_quantity_on_hand > 0
)

SELECT 
    sd.d_date AS sale_date,
    id.i_item_desc,
    id.i_current_price,
    COALESCE(rs.total_quantity, 0) AS total_quantity_sold,
    COALESCE(tr.total_returns, 0) AS total_returns,
    COALESCE(rs.total_net_paid, 0) AS total_revenue,
    CASE 
        WHEN COALESCE(rs.total_quantity, 0) > 0 THEN 
            (COALESCE(tr.total_returns, 0) * 100.0) / COALESCE(rs.total_quantity, 1) 
        ELSE 
            NULL 
    END AS return_rate
FROM date_dim sd
LEFT JOIN ranked_sales rs ON sd.d_date_sk = rs.ws_ship_date_sk
LEFT JOIN total_customer_returns tr ON rs.ws_item_sk = tr.sr_item_sk
JOIN item_details id ON id.i_item_sk = rs.ws_item_sk
WHERE sd.d_year = 2023
AND (id.i_current_price BETWEEN 20 AND 100)
ORDER BY sale_date, return_rate DESC;
