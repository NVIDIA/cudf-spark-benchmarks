
WITH  sales_data AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
),
customer_stats AS (
    SELECT
        c.c_customer_sk,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk, cd_gender
),
inventory_data AS (
    SELECT 
        i.i_item_sk,
        AVG(inv_quantity_on_hand) AS avg_quantity_on_hand,
        SUM(CASE WHEN inv_quantity_on_hand < 10 THEN 1 ELSE 0 END) AS low_stock_count
    FROM item i
    JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    GROUP BY i.i_item_sk
)
SELECT
    cs.c_customer_sk,
    cs.gender,
    cs.avg_purchase_estimate,
    sd.total_quantity,
    sd.total_sales_price,
    COALESCE(id.avg_quantity_on_hand, 0) AS avg_quantity_on_hand,
    COALESCE(id.low_stock_count, 0) AS low_stock_count,
    CASE 
        WHEN sd.rank = 1 AND cs.avg_purchase_estimate > 500 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_type
FROM customer_stats cs
LEFT JOIN sales_data sd ON cs.avg_purchase_estimate = sd.total_quantity
LEFT JOIN inventory_data id ON sd.ws_item_sk = id.i_item_sk
WHERE (cs.avg_purchase_estimate IS NOT NULL AND cs.avg_purchase_estimate > 250)
   OR sd.total_sales_price IS NOT NULL
ORDER BY cs.avg_purchase_estimate DESC, sd.total_quantity DESC;
