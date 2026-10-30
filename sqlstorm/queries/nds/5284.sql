
WITH sales_summary AS (
    SELECT 
        w.w_warehouse_name,
        d.d_year,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_sales_price) AS total_sales_value,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        income_band ib ON cd.cd_purchase_estimate BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
    WHERE 
        d.d_year BETWEEN 2020 AND 2022
        AND cd.cd_gender = 'F'
        AND w.w_state = 'CA'
    GROUP BY 
        w.w_warehouse_name, d.d_year
),
ranked_sales AS (
    SELECT 
        ws.w_warehouse_name,
        ws.d_year,
        ws.total_sales_quantity,
        ws.total_sales_value,
        ws.total_orders,
        RANK() OVER (PARTITION BY ws.d_year ORDER BY ws.total_sales_value DESC) AS sales_rank
    FROM 
        sales_summary ws
)
SELECT 
    w.w_warehouse_name,
    rs.d_year,
    rs.total_sales_quantity,
    rs.total_sales_value,
    rs.total_orders,
    rs.sales_rank
FROM 
    ranked_sales rs
JOIN 
    warehouse w ON rs.w_warehouse_name = w.w_warehouse_name
WHERE 
    rs.sales_rank <= 5
ORDER BY 
    rs.d_year, rs.sales_rank;
