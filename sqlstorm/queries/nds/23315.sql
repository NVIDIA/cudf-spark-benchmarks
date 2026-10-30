
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS rank
    FROM web_sales ws
    LEFT JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2022
    GROUP BY ws.ws_item_sk
),
Promotions AS (
    SELECT
        p.p_item_sk,
        COUNT(DISTINCT p.p_promo_id) AS promo_count,
        MAX(CASE WHEN p.p_discount_active = 'Y' THEN p.p_cost ELSE NULL END) AS max_active_discount
    FROM promotion p
    GROUP BY p.p_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_brand,
        COALESCE(inventory.inv_quantity_on_hand, 0) AS quantity_on_hand,
        COALESCE(cd.cd_marital_status, 'Unknown') AS marital_status,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate
    FROM item i
    LEFT JOIN inventory ON i.i_item_sk = inventory.inv_item_sk
    LEFT JOIN customer_demographics cd ON i.i_item_sk = cd.cd_demo_sk
)
SELECT
    id.i_item_sk,
    id.i_item_desc,
    id.i_brand,
    sd.total_quantity,
    sd.total_net_paid,
    p.promo_count,
    p.max_active_discount,
    ROUND((sd.total_net_paid / NULLIF(sd.total_quantity, 0)), 2) AS avg_net_paid_per_item,
    CASE 
        WHEN id.quantity_on_hand > 100 THEN 'Stocked'
        WHEN id.quantity_on_hand BETWEEN 1 AND 100 THEN 'Low Stock'
        ELSE 'Out of Stock'
    END AS stock_status,
    LAG(id.i_item_desc) OVER (ORDER BY sd.total_net_paid DESC) AS previous_item_desc
FROM ItemDetails id
LEFT JOIN SalesData sd ON id.i_item_sk = sd.ws_item_sk
LEFT JOIN Promotions p ON id.i_item_sk = p.p_item_sk
WHERE id.purchase_estimate > (SELECT AVG(purchase_estimate) FROM ItemDetails WHERE purchase_estimate IS NOT NULL)
  OR (id.marital_status = 'M' AND p.promo_count > 0)
ORDER BY avg_net_paid_per_item DESC
LIMIT 10;
