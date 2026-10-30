
WITH  sales_totals AS (
    SELECT 
        cs_item_sk,
        SUM(cs_net_paid) AS total_sales,
        COUNT(cs_order_number) AS order_count,
        RANK() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_net_paid) DESC) AS sales_rank
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk
),
customer_segment AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        hd.hd_income_band_sk,
        COUNT(*) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, hd.hd_income_band_sk
),
warehouse_summary AS (
    SELECT 
        w.w_warehouse_id,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        SUM(cs.cs_net_paid) AS total_revenue
    FROM 
        warehouse w
    LEFT JOIN 
        catalog_sales cs ON w.w_warehouse_sk = cs.cs_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    c.c_customer_id,
    cs.total_sales,
    cs.order_count,
    coalesce(ws.total_orders, 0) AS total_orders,
    coalesce(ws.total_revenue, 0) AS total_revenue,
    CASE 
        WHEN cs.sales_rank <= 10 THEN 'Top Performer' 
        ELSE 'Regular' 
    END AS performance_category
FROM 
    sales_totals cs
JOIN 
    customer_segment c ON cs.cs_item_sk = c.hd_income_band_sk
LEFT JOIN 
    warehouse_summary ws ON ws.total_orders > 0
WHERE 
    c.customer_count > 5 
    AND (c.cd_gender = 'M' OR c.cd_gender IS NULL)
ORDER BY 
    cs.total_sales DESC, 
    performance_category;
