
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_ship_mode_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        d.d_year,
        sm.sm_type
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE 
        d.d_year BETWEEN 2019 AND 2023
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_ship_mode_sk, d.d_year, sm.sm_type
),
shipping_summary AS (
    SELECT 
        d_year,
        sm_type,
        SUM(total_quantity) AS total_quantity,
        SUM(total_sales) AS total_sales,
        COUNT(total_orders) AS total_orders
    FROM 
        sales_data
    GROUP BY 
        d_year, sm_type
)
SELECT 
    s.d_year,
    s.sm_type,
    s.total_quantity,
    s.total_sales,
    s.total_orders,
    ROUND((s.total_sales / NULLIF(s.total_quantity, 0)), 2) AS avg_sales_per_unit
FROM 
    shipping_summary s
ORDER BY 
    s.d_year, s.sm_type;
