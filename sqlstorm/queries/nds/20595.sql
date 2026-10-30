
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number
),
heaviest_items AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
    HAVING 
        SUM(inv.inv_quantity_on_hand) > 100
),
average_customer_age AS (
    SELECT 
        AVG(EXTRACT(YEAR FROM CURRENT_DATE) - c.c_birth_year) AS avg_age
    FROM 
        customer c
    WHERE 
        c.c_birth_year IS NOT NULL
),
expensive_sales AS (
    SELECT 
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        CASE 
            WHEN cs.cs_ext_sales_price IS NULL THEN 0 
            ELSE cs.cs_ext_sales_price * 1.1 
        END AS adjusted_sales
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_ext_sales_price > (SELECT AVG(cs2.cs_ext_sales_price) FROM catalog_sales cs2)
),
return_metrics AS (
    SELECT 
        cr.cr_item_sk,
        COUNT(DISTINCT cr.cr_order_number) AS return_count,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
)
SELECT 
    item.i_item_id,
    item.i_item_desc,
    COALESCE(rs.total_quantity, 0) AS total_web_sales_quantity,
    COALESCE(heaviest.total_inventory, 0) AS total_inventory,
    avg_cust.avg_age,
    COALESCE(expensive.adjusted_sales, 0) AS expensive_sales_adjusted,
    COALESCE(rm.return_count, 0) AS return_count,
    COALESCE(rm.total_return_amount, 0) AS total_return_amount
FROM 
    item
LEFT JOIN 
    ranked_sales rs ON item.i_item_sk = rs.ws_item_sk AND rs.sales_rank = 1
LEFT JOIN 
    heaviest_items heaviest ON item.i_item_sk = heaviest.inv_item_sk
CROSS JOIN 
    average_customer_age avg_cust
LEFT JOIN 
    expensive_sales expensive ON item.i_item_sk = expensive.cs_item_sk
LEFT JOIN 
    return_metrics rm ON item.i_item_sk = rm.cr_item_sk
WHERE 
    (item.i_current_price - COALESCE(expensive.adjusted_sales, 0) > 0 OR 
    COALESCE(rm.return_count, 0) > 5)
ORDER BY 
    total_web_sales_quantity DESC, return_count ASC
LIMIT 100;
