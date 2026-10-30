
WITH demographic_summary AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY 
        cd_gender
),
sales_summary AS (
    SELECT 
        d.d_year,
        SUM(ws_net_profit) AS total_net_profit,
        SUM(ws_quantity) AS total_sales_quantity
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year > 2020
    GROUP BY 
        d.d_year
),
warehouse_summary AS (
    SELECT 
        w.w_warehouse_id,
        COUNT(DISTINCT inv.inv_item_sk) AS total_items_in_stock,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM 
        warehouse w
    JOIN 
        inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    ds.cd_gender,
    ds.total_customers,
    ds.avg_purchase_estimate,
    ds.total_dependents,
    ss.d_year,
    ss.total_net_profit,
    ss.total_sales_quantity,
    ws.w_warehouse_id,
    ws.total_items_in_stock,
    ws.total_quantity_on_hand
FROM 
    demographic_summary ds
JOIN 
    sales_summary ss ON ds.total_customers > 1000
JOIN 
    warehouse_summary ws ON ss.total_net_profit > 50000
ORDER BY 
    ds.total_customers DESC, 
    ss.d_year DESC, 
    ws.total_quantity_on_hand DESC;
