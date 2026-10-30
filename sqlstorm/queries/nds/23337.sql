
WITH RankedSales AS (
    SELECT
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_ext_discount_amt,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
PromotionalItems AS (
    SELECT
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_ext_sales_price) AS total_sales
    FROM catalog_sales
    WHERE cs_promo_sk IN (
        SELECT p_promo_sk
        FROM promotion
        WHERE p_discount_active = 'Y' AND p_start_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim)
    )
    GROUP BY cs_item_sk
    HAVING SUM(cs_quantity) > 5 
),
InventoryCheck AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk
),
FinalResults AS (
    SELECT
        cs.cs_item_sk,
        cs.total_sales,
        ir.total_on_hand,
        COALESCE(rs.ws_sales_price, 0) AS last_known_price,
        COALESCE(rs.ws_ext_discount_amt, 0) AS last_discount,
        CASE 
            WHEN ir.total_on_hand IS NULL THEN 'Out of Stock'
            WHEN ir.total_on_hand < 10 THEN 'Low Stock'
            ELSE 'In Stock'
        END AS stock_status
    FROM PromotionalItems cs
    LEFT JOIN InventoryCheck ir ON cs.cs_item_sk = ir.inv_item_sk
    LEFT JOIN RankedSales rs ON cs.cs_item_sk = rs.ws_item_sk AND rs.rn = 1
)
SELECT
    f.cs_item_sk,
    f.total_sales,
    f.total_on_hand,
    f.last_known_price,
    f.last_discount,
    f.stock_status
FROM FinalResults f
WHERE f.stock_status = 'Low Stock' OR f.total_sales > 1000
ORDER BY f.total_sales DESC;
