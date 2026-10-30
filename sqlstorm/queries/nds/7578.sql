
WITH sales_summary AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    JOIN 
        date_dim d ON ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        d.d_year, d.d_month_seq
),
demographic_summary AS (
    SELECT 
        c.c_birth_month,
        AVG(cd_dep_count) AS avg_dependents,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_birth_month
),
warehouse_summary AS (
    SELECT 
        w.w_warehouse_id,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    JOIN 
        warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    ss.d_year,
    ss.d_month_seq,
    ss.total_sales,
    ss.avg_net_profit,
    ds.customer_count,
    ds.avg_dependents,
    ws.w_warehouse_id,
    ws.total_inventory
FROM 
    sales_summary ss
JOIN 
    demographic_summary ds ON ds.c_birth_month = EXTRACT(MONTH FROM DATE(CONCAT(ss.d_year, '-', ss.d_month_seq, '-01')))
JOIN 
    warehouse_summary ws ON ws.w_warehouse_id IN ('W0001', 'W0002', 'W0003')
ORDER BY 
    ss.d_year, ss.d_month_seq;
