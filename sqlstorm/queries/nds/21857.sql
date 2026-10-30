
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
high_value_items AS (
    SELECT 
        item.i_item_sk,
        item.i_item_desc,
        COALESCE(inventory.inv_quantity_on_hand, 0) AS stock_level,
        promotion.p_promo_name,
        RANK() OVER (ORDER BY COALESCE(SUM(ws.ws_net_paid), 0) DESC) AS item_sales_rank,
        item.i_current_price,
        item.i_brand_id
    FROM 
        item
    LEFT JOIN 
        web_sales ws ON item.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        inventory ON item.i_item_sk = inventory.inv_item_sk
    LEFT JOIN 
        promotion ON item.i_item_sk = promotion.p_item_sk
    WHERE 
        item.i_current_price > (SELECT AVG(i_current_price) FROM item) 
    GROUP BY 
        item.i_item_sk, item.i_item_desc, inventory.inv_quantity_on_hand, promotion.p_promo_name, item.i_current_price, item.i_brand_id
),
item_stock_status AS (
    SELECT 
        hi.item_sales_rank,
        hi.i_item_sk,
        hi.i_item_desc,
        hi.stock_level,
        CASE 
            WHEN hi.stock_level > 0 THEN 'In Stock'
            ELSE 'Out of Stock'
        END AS stock_status,
        CASE 
            WHEN hi.item_sales_rank IS NULL THEN 'Not Ranked'
            ELSE 'Ranked'
        END AS sales_status
    FROM 
        high_value_items hi
)
SELECT 
    iss.i_item_sk,
    iss.i_item_desc,
    iss.stock_level,
    iss.stock_status,
    iss.sales_status,
    iss.item_sales_rank
FROM 
    item_stock_status iss
WHERE 
    iss.stock_status = 'In Stock' 
    AND iss.item_sales_rank <= 10
UNION ALL
SELECT 
    NULL AS i_item_sk,
    'Total Count of High Value Items' AS i_item_desc,
    COUNT(*) AS stock_level,
    NULL AS stock_status,
    'Summary' AS sales_status,
    NULL AS item_sales_rank
FROM 
    item_stock_status 
WHERE 
    stock_status = 'In Stock'
ORDER BY 
    i_item_sk DESC NULLS LAST;
