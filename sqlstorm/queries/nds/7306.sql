
WITH customer_stats AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS total_customers,
        SUM(cd_dep_count) AS avg_deps,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
),
sales_summary AS (
    SELECT 
        d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        d_year
),
warehouse_stats AS (
    SELECT 
        w_warehouse_id,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory
    JOIN 
        warehouse ON inv_warehouse_sk = w_warehouse_sk
    GROUP BY 
        w_warehouse_id
)
SELECT 
    cs.cd_gender,
    cs.total_customers,
    cs.avg_deps,
    ss.d_year,
    ss.total_sales,
    ss.total_profit,
    ws.w_warehouse_id,
    ws.total_inventory
FROM 
    customer_stats cs
JOIN 
    sales_summary ss ON 1=1
JOIN 
    warehouse_stats ws ON 1=1
ORDER BY 
    cs.cd_gender, ss.d_year;
