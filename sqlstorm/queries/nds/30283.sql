
WITH  SalesCTE AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    GROUP BY
        ws_sold_date_sk,
        ws_item_sk
),
Inventories AS (
    SELECT
        inv_date_sk,
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM
        inventory
    GROUP BY
        inv_date_sk,
        inv_item_sk
),
SalesInventory AS (
    SELECT
        s.ws_item_sk,
        s.total_orders,
        s.total_sales,
        i.total_inventory,
        COALESCE(i.total_inventory, 0) AS effective_inventory,
        CASE
            WHEN i.total_inventory IS NULL THEN 'No Inventory'
            WHEN i.total_inventory < 100 THEN 'Low Inventory'
            ELSE 'Sufficient Inventory'
        END AS inventory_status
    FROM
        SalesCTE s
    LEFT JOIN
        Inventories i ON s.ws_item_sk = i.inv_item_sk
)
SELECT
    a.ca_state,
    COUNT(DISTINCT s.ws_item_sk) AS distinct_items_sold,
    SUM(s.total_sales) AS total_revenue,
    AVG(s.total_orders) AS avg_orders_per_item,
    MAX(s.effective_inventory) AS max_inventory
FROM
    SalesInventory s
JOIN
    customer c ON s.ws_item_sk = c.c_customer_sk
JOIN
    customer_address a ON c.c_current_addr_sk = a.ca_address_sk
WHERE
    a.ca_state IS NOT NULL
GROUP BY
    a.ca_state
HAVING
    SUM(s.total_sales) > 10000
ORDER BY
    total_revenue DESC
LIMIT 10;
