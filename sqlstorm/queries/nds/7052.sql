
WITH sales_data AS (
    SELECT 
        d.d_year,
        sm.sm_type,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE 
        d.d_year BETWEEN 2015 AND 2022
    GROUP BY 
        d.d_year, sm.sm_type
),
tmp AS (
    SELECT 
        d_year,
        sm_type,
        total_sales,
        total_orders,
        unique_customers,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS rank
    FROM 
        sales_data
)
SELECT 
    d_year,
    sm_type,
    total_sales,
    total_orders,
    unique_customers
FROM 
    tmp
WHERE 
    rank <= 3
ORDER BY 
    d_year, total_sales DESC;
