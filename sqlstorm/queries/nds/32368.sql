
WITH  sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    UNION ALL
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_net_paid_inc_tax) DESC) AS rank
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk
),
item_inventory AS (
    SELECT 
        i_item_sk,
        i_product_name,
        COALESCE(SUM(inv_quantity_on_hand), 0) AS total_inventory
    FROM 
        item
    LEFT JOIN 
        inventory ON i_item_sk = inv_item_sk
    GROUP BY 
        i_item_sk, i_product_name
),
final_summary AS (
    SELECT 
        i.i_product_name AS product_name,
        COALESCE(s.total_quantity, 0) AS total_quantity_sold,
        COALESCE(s.total_sales, 0) AS total_sales,
        COALESCE(i.total_inventory, 0) AS total_inventory,
        CASE 
            WHEN COALESCE(i.total_inventory, 0) = 0 THEN 'Out of Stock'
            ELSE 'In Stock'
        END AS stock_status
    FROM 
        item_inventory i
    LEFT JOIN 
        sales_summary s ON i.i_item_sk = s.ws_item_sk
)
SELECT 
    product_name,
    total_quantity_sold,
    total_sales,
    total_inventory,
    stock_status
FROM 
    final_summary
WHERE 
    total_sales > 1000
ORDER BY 
    total_sales DESC
LIMIT 50;
