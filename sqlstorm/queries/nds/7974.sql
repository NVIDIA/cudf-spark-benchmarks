
WITH customer_counts AS (
    SELECT 
        cd_gender, 
        COUNT(DISTINCT c_customer_sk) AS total_customers, 
        SUM(CASE WHEN cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_customers, 
        SUM(CASE WHEN cd_marital_status = 'S' THEN 1 ELSE 0 END) AS single_customers
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
),
sales_summary AS (
    SELECT 
        ws.ws_ship_mode_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales_revenue
    FROM 
        web_sales AS ws
    JOIN 
        ship_mode AS sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        ws.ws_ship_mode_sk
),
inventory_info AS (
    SELECT 
        inv.inv_item_sk, 
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory AS inv
    GROUP BY 
        inv.inv_item_sk
),
item_sales_feedback AS (
    SELECT 
        i.i_item_sk, 
        i.i_item_id, 
        COALESCE(ss.total_quantity_sold, 0) AS total_quantity_sold, 
        COALESCE(ss.total_sales_revenue, 0) AS total_sales_revenue, 
        COALESCE(ii.total_inventory, 0) AS total_inventory,
        CASE WHEN COALESCE(ss.total_quantity_sold, 0) > COALESCE(ii.total_inventory, 0) THEN 'Over Sold' 
             ELSE 'Stocked' END AS inventory_status
    FROM 
        item AS i
    LEFT JOIN 
        sales_summary AS ss ON i.i_item_sk = ss.ws_ship_mode_sk
    LEFT JOIN 
        inventory_info AS ii ON i.i_item_sk = ii.inv_item_sk
)
SELECT 
    cc.cd_gender,
    cc.total_customers,
    cc.married_customers,
    cc.single_customers,
    isb.i_item_id,
    isb.total_quantity_sold,
    isb.total_sales_revenue,
    isb.total_inventory,
    isb.inventory_status
FROM 
    customer_counts AS cc
JOIN 
    item_sales_feedback AS isb ON cc.cd_gender = CASE WHEN isb.total_sales_revenue > 0 THEN 'M' ELSE 'S' END
ORDER BY 
    cc.cd_gender, isb.total_sales_revenue DESC;
