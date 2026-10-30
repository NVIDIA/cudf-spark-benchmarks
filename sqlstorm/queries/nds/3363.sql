WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales_amount,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE 
        p.p_discount_active = 'Y'
        AND i.i_current_price > 20.00
    GROUP BY 
        ws.ws_item_sk
),
top_sales AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity_sold,
        ss.total_sales_amount,
        ss.total_orders
    FROM 
        sales_summary ss
    WHERE 
        ss.rank <= 10
),
inventory_data AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(ts.total_quantity_sold, 0) AS total_quantity_sold,
    COALESCE(ts.total_sales_amount, 0) AS total_sales_amount,
    COALESCE(ts.total_orders, 0) AS total_orders,
    COALESCE(id.total_quantity_on_hand, 0) AS total_quantity_on_hand
FROM 
    item i
LEFT JOIN 
    top_sales ts ON i.i_item_sk = ts.ws_item_sk
LEFT JOIN 
    inventory_data id ON i.i_item_sk = id.inv_item_sk
WHERE 
    i.i_rec_start_date <= cast('2002-10-01' as date)
    AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date > cast('2002-10-01' as date))
ORDER BY 
    total_quantity_sold DESC;