
WITH sales_data AS (
    SELECT 
        ws.ws_sales_price,
        ws.ws_quantity,
        ci.c_first_name,
        ci.c_last_name,
        ci.c_birth_year,
        ci.c_birth_month,
        inv.inv_quantity_on_hand,
        wd.w_warehouse_name,
        sm.sm_type,
        ds.d_year,
        ds.d_month_seq
    FROM 
        web_sales ws
    JOIN 
        customer ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
    JOIN 
        inventory inv ON ws.ws_item_sk = inv.inv_item_sk
    JOIN 
        warehouse wd ON inv.inv_warehouse_sk = wd.w_warehouse_sk
    JOIN 
        date_dim ds ON ws.ws_sold_date_sk = ds.d_date_sk
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE 
        ds.d_year = 2023
        AND ws.ws_sales_price > 0
        AND inv.inv_quantity_on_hand < 50
),
aggregated_data AS (
    SELECT 
        d_month_seq,
        d_year,
        AVG(ws_sales_price) AS avg_sales_price,
        SUM(ws_quantity) AS total_quantity_sold,
        COUNT(DISTINCT c_first_name || ' ' || c_last_name) AS distinct_customers,
        COUNT(*) AS total_sales_count
    FROM 
        sales_data
    GROUP BY 
        d_month_seq, d_year
)
SELECT 
    a.d_month_seq,
    a.d_year,
    a.avg_sales_price,
    a.total_quantity_sold,
    a.distinct_customers,
    a.total_sales_count,
    ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.total_quantity_sold DESC) AS sales_rank
FROM 
    aggregated_data a
ORDER BY 
    a.d_year, a.d_month_seq;
