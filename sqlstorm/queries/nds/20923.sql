
WITH  sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales_quantity,
        SUM(ws_sales_price * ws_quantity) AS total_sales_value,
        AVG(ws_sales_price) AS avg_sales_price
    FROM web_sales
    GROUP BY ws_item_sk
), 
inventory_data AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory,
        MIN(inv_date_sk) AS first_inventory_date,
        MAX(inv_date_sk) AS last_inventory_date
    FROM inventory
    GROUP BY inv_item_sk
), 
sales_summary AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_sales_quantity,
        sd.total_sales_value,
        sd.avg_sales_price,
        COALESCE(id.total_inventory, 0) AS total_inventory,
        id.first_inventory_date,
        id.last_inventory_date,
        CASE 
            WHEN id.total_inventory IS NULL THEN 'No Inventory'
            WHEN id.total_inventory < sd.total_sales_quantity THEN 'Low Stock'
            ELSE 'Sufficient Stock' 
        END AS stock_status
    FROM sales_data sd
    LEFT JOIN inventory_data id ON sd.ws_item_sk = id.inv_item_sk
), 
promotions_data AS (
    SELECT 
        p.p_item_sk,
        COUNT(p.p_promo_name) AS promo_count,
        MAX(p.p_cost) AS max_promo_cost
    FROM promotion p
    WHERE p.p_start_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim) 
      AND p.p_end_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim)
    GROUP BY p.p_item_sk
)
SELECT 
    ss.ws_item_sk,
    ss.total_sales_quantity,
    ss.total_sales_value,
    ss.avg_sales_price,
    ss.total_inventory,
    ss.first_inventory_date,
    ss.last_inventory_date,
    ss.stock_status,
    COALESCE(pd.promo_count, 0) AS total_promotions,
    pd.max_promo_cost,
    CASE 
        WHEN ss.stock_status = 'No Inventory' 
        THEN 'Supply Chain Issue' 
        WHEN ss.total_sales_value > 10000 THEN 'High Revenue Item' 
        ELSE 'Standard Item' 
    END AS item_classification
FROM sales_summary ss
LEFT JOIN promotions_data pd ON ss.ws_item_sk = pd.p_item_sk
WHERE ss.total_sales_quantity > (
        SELECT AVG(total_sales_quantity)
        FROM sales_summary
    ) 
    OR ss.total_inventory IS NULL
ORDER BY ss.total_sales_value DESC, ss.total_sales_quantity ASC;
