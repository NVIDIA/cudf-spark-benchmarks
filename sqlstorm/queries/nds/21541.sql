
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        COALESCE(sm.sm_type, 'Unknown') AS shipping_type,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity
    FROM 
        web_sales ws
    LEFT JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE 
        ws.ws_sales_price IS NOT NULL
),
filtered_sales AS (
    SELECT 
        r.ws_item_sk,
        r.ws_order_number,
        r.ws_sales_price,
        r.shipping_type,
        r.total_quantity,
        CASE 
            WHEN r.shipping_type = 'Air' AND r.total_quantity > 100 THEN 'High Volume Air Sales'
            WHEN r.shipping_type = 'Ground' AND r.total_quantity <= 50 THEN 'Low Volume Ground Sales'
            ELSE 'Standard Sales'
        END AS sales_category
    FROM 
        ranked_sales r
    WHERE 
        r.price_rank <= 5
),
store_sales_data AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_sales_price) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_transaction_count
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_item_sk
),
inventory_data AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    fs.ws_item_sk,
    fs.ws_order_number,
    fs.ws_sales_price,
    fs.shipping_type,
    fs.total_quantity,
    fs.sales_category,
    COALESCE(ss.total_store_sales, 0) AS total_store_sales,
    COALESCE(id.total_inventory, 0) AS total_inventory_on_hand
FROM 
    filtered_sales fs
LEFT JOIN 
    store_sales_data ss ON fs.ws_item_sk = ss.ss_item_sk
LEFT JOIN 
    inventory_data id ON fs.ws_item_sk = id.inv_item_sk
WHERE 
    fs.shipping_type IS NOT NULL
    AND (fs.total_quantity IS NOT NULL OR fs.ws_sales_price > 50)
    AND (ss.store_transaction_count > 0 OR id.total_inventory IS NULL)
ORDER BY 
    fs.sales_category, 
    total_quantity DESC
LIMIT 100;
