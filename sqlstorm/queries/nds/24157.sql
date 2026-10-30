WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_paid,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS revenue_rank
    FROM
        web_sales AS ws
    GROUP BY
        ws.ws_item_sk
),
inventory_check AS (
    SELECT
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) as total_inventory
    FROM
        inventory AS inv
    GROUP BY
        inv.inv_item_sk
    HAVING
        SUM(inv.inv_quantity_on_hand) > 0
)
SELECT 
    s_item.i_item_id,
    s_item.i_item_desc,
    COALESCE(ss.total_quantity, 0) AS quantity_sold,
    COALESCE(ss.total_paid, 0) AS total_revenue,
    ic.total_inventory AS available_inventory,
    CASE 
        WHEN ss.revenue_rank IS NULL THEN 'Not Sold'
        ELSE 'Sold' 
    END AS sales_status
FROM 
    item AS s_item
LEFT OUTER JOIN 
    sales_summary AS ss ON s_item.i_item_sk = ss.ws_item_sk
JOIN 
    inventory_check AS ic ON s_item.i_item_sk = ic.inv_item_sk
WHERE 
    (s_item.i_current_price > 100 OR s_item.i_wholesale_cost IS NULL)
    AND (s_item.i_formulation IN ('Tablet', 'Liquid') OR s_item.i_color IS NOT NULL)
    AND s_item.i_rec_start_date <= cast('2002-10-01' as date) 
    AND (s_item.i_rec_end_date IS NULL OR s_item.i_rec_end_date > cast('2002-10-01' as date))
ORDER BY 
    total_revenue DESC 
LIMIT 10;