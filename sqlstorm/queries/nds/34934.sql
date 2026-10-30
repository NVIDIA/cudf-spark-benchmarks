
WITH  top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        SUM(ws.ws_net_profit) > 1000
),
date_range AS (
    SELECT 
        d.d_date_sk,
        d.d_date,
        DENSE_RANK() OVER (ORDER BY d.d_date) AS date_rank
    FROM 
        date_dim d
    WHERE 
        d.d_date > '2022-01-01'
),
inventory_data AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity,
        MAX(inv.inv_date_sk) as last_updated_date_sk
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
sales_summary AS (
    SELECT 
        CASE 
            WHEN sm.sm_type IS NULL THEN 'Unknown'
            ELSE sm.sm_type 
        END AS shipping_method,
        COUNT(ws.ws_order_number) AS total_orders,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_sales
    FROM 
        web_sales ws
    LEFT JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        sm.sm_type
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    dr.d_date,
    ss.shipping_method,
    ss.total_orders,
    ss.total_sales,
    inv.total_quantity,
    (CASE 
        WHEN inv.total_quantity IS NULL THEN 'No Inventory'
        WHEN inv.total_quantity < 10 THEN 'Low Inventory' 
        ELSE 'Sufficient Inventory' 
    END) AS inventory_status
FROM 
    top_customers tc
JOIN 
    date_range dr ON dr.date_rank <= 5
JOIN 
    sales_summary ss ON ss.total_orders > 5
LEFT JOIN 
    inventory_data inv ON tc.c_customer_sk = inv.inv_item_sk
WHERE 
    (tc.total_profit IS NOT NULL AND tc.profit_rank <= 50)
    OR ss.total_sales > 5000
ORDER BY 
    tc.total_profit DESC, 
    dr.d_date DESC;
