
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
high_value_items AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        inv.inv_quantity_on_hand,
        CASE 
            WHEN inv.inv_quantity_on_hand IS NULL THEN 'Out of Stock'
            ELSE 'In Stock'
        END AS stock_status
    FROM 
        item i
    LEFT JOIN 
        inventory inv ON i.i_item_sk = inv.inv_item_sk
    WHERE 
        i.i_current_price > (SELECT AVG(i_current_price) FROM item WHERE i_rec_end_date IS NULL)
)
SELECT 
    hvi.i_item_sk,
    hvi.i_item_desc,
    hvi.i_current_price,
    hvi.stock_status,
    COALESCE(rs.total_quantity, 0) AS total_sales_quantity,
    COALESCE(rs.total_sales, 0) AS total_sales_amount
FROM 
    high_value_items hvi
LEFT JOIN 
    ranked_sales rs ON hvi.i_item_sk = rs.ws_item_sk AND rs.sales_rank = 1
WHERE 
    hvi.stock_status = 'In Stock'
ORDER BY 
    total_sales_amount DESC
LIMIT 10;
