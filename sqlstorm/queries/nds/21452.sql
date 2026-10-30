
WITH  sales_totals AS (
    SELECT
        ws_item_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rn
    FROM web_sales
    GROUP BY ws_item_sk
),
profit_analysis AS (
    SELECT
        st.ws_item_sk,
        st.total_profit,
        sd.sm_type,
        COALESCE(NULLIF(sd.sm_type, 'Standard'), 'Other') AS category,
        st.order_count,
        CASE
            WHEN st.total_profit > 1000 THEN 'High Profit'
            WHEN st.total_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
            ELSE 'Low Profit'
        END AS profit_level
    FROM sales_totals st
    LEFT JOIN ship_mode sd ON st.ws_item_sk = sd.sm_ship_mode_sk
    WHERE st.rn = 1
),
inventory_check AS (
    SELECT
        i.inv_item_sk,
        SUM(i.inv_quantity_on_hand) AS total_quantity
    FROM inventory i
    GROUP BY i.inv_item_sk
)
SELECT
    pa.ws_item_sk,
    pa.total_profit,
    pa.category,
    pa.order_count,
    pa.profit_level,
    ic.total_quantity,
    CASE 
        WHEN ic.total_quantity IS NULL THEN 'No Stock'
        ELSE 'In Stock'
    END AS stock_status
FROM profit_analysis pa
FULL OUTER JOIN inventory_check ic ON pa.ws_item_sk = ic.inv_item_sk
WHERE pa.total_profit IS NOT NULL OR ic.total_quantity IS NOT NULL
ORDER BY pa.profit_level DESC, ic.total_quantity DESC NULLS LAST;
