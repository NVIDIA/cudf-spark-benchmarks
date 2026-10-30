
WITH sales_data AS (
    SELECT 
        w.w_warehouse_id,
        s.s_store_id,
        i.i_item_id,
        SUM(ss.ss_quantity) AS total_sold,
        SUM(ss.ss_net_paid) AS total_revenue,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    JOIN 
        warehouse w ON s.s_company_id = w.w_warehouse_sk
    JOIN 
        item i ON ss.ss_item_sk = i.i_item_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN (
            SELECT d.d_date_sk FROM date_dim d WHERE d.d_date = '2023-01-01'
        ) AND (
            SELECT d.d_date_sk FROM date_dim d WHERE d.d_date = '2023-12-31'
        )
    GROUP BY 
        w.w_warehouse_id, s.s_store_id, i.i_item_id
)
SELECT 
    wd.w_warehouse_id AS warehouse_id,
    sd.s_store_id AS store_id,
    sd.i_item_id AS item_id,
    sd.total_sold,
    sd.total_revenue,
    CASE 
        WHEN sd.total_revenue > 10000 THEN 'High Revenue'
        WHEN sd.total_revenue BETWEEN 5000 AND 10000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM 
    sales_data sd
JOIN 
    (SELECT DISTINCT w.w_warehouse_id FROM warehouse w) wd ON sd.w_warehouse_id = wd.w_warehouse_id
ORDER BY 
    sd.total_revenue DESC
LIMIT 100;
