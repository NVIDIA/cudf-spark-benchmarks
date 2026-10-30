
WITH  sales_data AS (
    SELECT 
        ws_ship_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_ship_date_sk, ws_item_sk
),
customer_summary AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(COALESCE(cd_dep_count, 0)) AS total_dependents,
        AVG(cd_purchase_estimate) AS average_purchase_estimate
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ca_state
),
top_items AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales
    FROM sales_data sd
    WHERE sd.sales_rank <= 10
),
inventory_data AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM inventory inv
    GROUP BY inv.inv_item_sk
)
SELECT 
    ci.ca_state,
    ci.customer_count,
    ci.total_dependents,
    ci.average_purchase_estimate,
    ti.ws_item_sk,
    ti.total_quantity,
    ti.total_sales,
    COALESCE(inv.total_inventory, 0) AS total_inventory
FROM customer_summary ci
JOIN top_items ti ON EXISTS (
    SELECT 1 FROM inventory_data inv WHERE ti.ws_item_sk = inv.inv_item_sk
)
LEFT JOIN inventory_data inv ON ti.ws_item_sk = inv.inv_item_sk
ORDER BY ci.customer_count DESC, ti.total_sales DESC
LIMIT 20;
