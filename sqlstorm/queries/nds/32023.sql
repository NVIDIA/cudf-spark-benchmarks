
WITH  daily_sales AS (
    SELECT 
        d.d_date AS sale_date, 
        SUM(ws.ws_ext_sales_price) AS total_sales_price,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY d.d_date) AS day_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        d.d_date, d.d_year
),
top_days AS (
    SELECT 
        sale_date, 
        total_sales_price, 
        total_net_paid, 
        order_count,
        ROW_NUMBER() OVER (ORDER BY total_net_paid DESC) AS rank
    FROM 
        daily_sales
)
SELECT 
    td.sale_date, 
    td.total_sales_price,
    td.total_net_paid,
    td.order_count,
    CASE 
        WHEN td.total_net_paid > 10000 THEN 'High Performer'
        WHEN td.total_net_paid BETWEEN 5000 AND 10000 THEN 'Medium Performer'
        ELSE 'Low Performer'
    END AS performance_category,
    COALESCE(sm.sm_type, 'Unknown') AS shipping_mode
FROM 
    top_days td
LEFT JOIN 
    ship_mode sm ON td.rank = sm.sm_ship_mode_sk
WHERE 
    td.rank <= 10
ORDER BY 
    td.total_net_paid DESC;
