
WITH sales_summary AS (
    SELECT 
        s.s_store_id,
        SUM(ss_ext_sales_price) AS total_sales,
        AVG(ss_sales_price) AS average_price,
        COUNT(ss_ticket_number) AS total_transactions
    FROM 
        store_sales
    JOIN 
        store s ON s.s_store_sk = store_sales.ss_store_sk
    JOIN 
        date_dim d ON d.d_date_sk = store_sales.ss_sold_date_sk
    WHERE 
        d.d_year = 2023 
        AND d.d_moy BETWEEN 1 AND 6
    GROUP BY 
        s.s_store_id
), customer_summary AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        SUM(cs_ext_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        cd.cd_gender
), warehouse_summary AS (
    SELECT 
        w.w_warehouse_id,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM 
        warehouse w
    JOIN 
        inventory i ON w.w_warehouse_sk = i.inv_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    ss.s_store_id,
    cs.cd_gender,
    ss.total_sales,
    cs.customer_count,
    ws.w_warehouse_id,
    ws.total_inventory
FROM 
    sales_summary ss
LEFT JOIN 
    customer_summary cs ON cs.total_spent > 0
JOIN 
    warehouse_summary ws ON ws.total_inventory > 0
ORDER BY 
    total_sales DESC, customer_count DESC;
