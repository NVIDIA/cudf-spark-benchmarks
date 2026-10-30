
WITH sales_data AS (
    SELECT 
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_ext_sales_price,
        c.c_first_name,
        c.c_last_name,
        d.d_date,
        w.w_warehouse_name,
        sm.sm_type
    FROM 
        catalog_sales cs
    JOIN 
        customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN 
        warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN 
        ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE 
        d.d_year = 2023 AND
        cs.cs_quantity > 0
),
aggregated_sales AS (
    SELECT 
        w_warehouse_name,
        sm_type,
        COUNT(cs_order_number) AS total_orders,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_ext_sales_price) AS total_sales
    FROM 
        sales_data
    GROUP BY 
        w_warehouse_name, sm_type
),
ranked_sales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY w_warehouse_name ORDER BY total_sales DESC) AS sales_rank
    FROM 
        aggregated_sales
)
SELECT 
    w_warehouse_name,
    sm_type,
    total_orders,
    total_quantity,
    total_sales,
    sales_rank
FROM 
    ranked_sales
WHERE 
    sales_rank <= 5
ORDER BY 
    w_warehouse_name, sales_rank;
