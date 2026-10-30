WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS price_rank
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
),
TopSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        COUNT(*) AS sales_count
    FROM 
        RankedSales
    WHERE 
        price_rank <= 5
    GROUP BY 
        ws_item_sk
),
StoreInventory AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
),
FinalResults AS (
    SELECT 
        t.ws_item_sk,
        t.total_quantity,
        COALESCE(i.total_inventory, 0) AS available_inventory,
        CASE 
            WHEN COALESCE(i.total_inventory, 0) = 0 THEN 'Out of Stock'
            WHEN t.total_quantity > COALESCE(i.total_inventory, 0) THEN 'Over Sold'
            ELSE 'In Stock'
        END AS stock_status
    FROM 
        TopSales t
    LEFT JOIN 
        StoreInventory i ON t.ws_item_sk = i.inv_item_sk
)
SELECT 
    f.ws_item_sk,
    f.total_quantity,
    f.available_inventory,
    f.stock_status,
    (CASE
        WHEN f.stock_status = 'Out of Stock' THEN 'Contact support'
        ELSE 'Good to go'
    END) AS status_message
FROM 
    FinalResults f
WHERE 
    f.total_quantity > 0
ORDER BY 
    f.ws_item_sk;