
WITH ranked_sales AS (
    SELECT 
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_sales_price,
        cs.cs_ext_discount_amt,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_net_profit DESC) AS rn,
        (CASE 
            WHEN cs.cs_list_price IS NULL THEN 0 
            ELSE cs.cs_sales_price / cs.cs_list_price 
        END) AS price_ratio
    FROM catalog_sales cs
    WHERE cs.cs_sales_price > 0
    AND cs.cs_sold_date_sk IN (
        SELECT d.d_date_sk 
        FROM date_dim d 
        WHERE d.d_year = 2023 AND d.d_moy IN (1, 2, 3) 
        AND d.d_weekend = 'Y'
    )
),
total_sales AS (
    SELECT 
        rs.cs_item_sk,
        SUM(rs.cs_sales_price) AS total_sales_price,
        SUM(rs.cs_ext_discount_amt) AS total_discount,
        COUNT(*) AS sales_count
    FROM ranked_sales rs
    WHERE rs.rn <= 10
    GROUP BY rs.cs_item_sk
),
inventory_stats AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory,
        COUNT(DISTINCT CASE WHEN inv.inv_quantity_on_hand IS NULL THEN inv.inv_quantity_on_hand END) AS null_inventory_count
    FROM inventory inv
    GROUP BY inv.inv_item_sk
)
SELECT 
    t.i_item_sk AS item_id,
    ts.total_sales_price,
    ts.total_discount,
    iv.total_inventory,
    (CASE 
        WHEN iv.total_inventory = 0 THEN 'Out of Stock'
        ELSE 'In Stock'
    END) AS stock_status,
    'The item ' || t.i_item_desc || ' has a total sales price of ' || COALESCE(ts.total_sales_price, 0) || 
    ' with a discount of ' || COALESCE(ts.total_discount, 0) || 
    ' and is currently ' || (CASE WHEN (iv.total_inventory IS NULL OR iv.total_inventory < 1) THEN 'out of stock' ELSE 'in stock' END) || 
    '.' AS stock_message
FROM item t
LEFT JOIN total_sales ts ON t.i_item_sk = ts.cs_item_sk
LEFT JOIN inventory_stats iv ON t.i_item_sk = iv.inv_item_sk
WHERE (ts.sales_count > 5 OR (iv.null_inventory_count > 0 AND iv.total_inventory IS NULL));
