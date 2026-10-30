
WITH customer_stats AS (
    SELECT 
        cd_gender, 
        COUNT(DISTINCT c_customer_sk) AS customer_count, 
        AVG(cd_purchase_estimate) AS avg_purchase_estimate, 
        SUM(hd_dep_count) AS total_dependents
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN 
        household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
    GROUP BY 
        cd_gender
),
sales_summary AS (
    SELECT 
        d.d_year, 
        SUM(ws_ext_sales_price) AS total_sales, 
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
),
warehouse_details AS (
    SELECT 
        w.w_warehouse_id, 
        AVG(inv_quantity_on_hand) AS avg_inventory
    FROM 
        inventory inv
    JOIN 
        warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    cs.cd_gender,
    cs.customer_count,
    cs.avg_purchase_estimate,
    cs.total_dependents,
    ss.total_sales,
    ss.total_profit,
    wd.w_warehouse_id,
    wd.avg_inventory
FROM 
    customer_stats cs
JOIN 
    sales_summary ss ON cs.customer_count > 1000
JOIN 
    warehouse_details wd ON wd.avg_inventory > 500
ORDER BY 
    cs.customer_count DESC, ss.total_sales DESC;
