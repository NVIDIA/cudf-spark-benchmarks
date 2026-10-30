
WITH SalesData AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        sm.sm_type,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        d.d_year, d.d_month_seq, sm.sm_type
),
AggregatedSales AS (
    SELECT 
        d_year,
        d_month_seq,
        sm_type,
        total_quantity,
        total_sales,
        total_orders,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
    FROM SalesData
)
SELECT 
    d_year,
    d_month_seq,
    sm_type,
    total_quantity,
    total_sales,
    total_orders,
    sales_rank
FROM 
    AggregatedSales
WHERE 
    sales_rank <= 5
ORDER BY 
    d_year, total_sales DESC;
