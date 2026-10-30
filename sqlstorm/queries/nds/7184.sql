
WITH sales_summary AS (
    SELECT 
        d.d_year AS sales_year,
        d.d_month_seq AS sales_month,
        COUNT(ws.ws_order_number) AS total_sales,
        SUM(ws.ws_ext_sales_price) AS total_revenue,
        AVG(ws.ws_net_paid_inc_tax) AS average_order_value
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
        AND cd.cd_gender = 'F'
        AND ws.ws_ship_mode_sk IN (SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_type LIKE '%Express%')
    GROUP BY 
        d.d_year, d.d_month_seq
),
monthly_trends AS (
    SELECT 
        sales_year,
        sales_month,
        total_sales,
        total_revenue,
        average_order_value,
        LAG(total_revenue) OVER (PARTITION BY sales_year ORDER BY sales_month) AS last_month_revenue,
        LAG(total_sales) OVER (PARTITION BY sales_year ORDER BY sales_month) AS last_month_sales
    FROM 
        sales_summary
)
SELECT 
    sales_year,
    sales_month,
    total_sales,
    total_revenue,
    average_order_value,
    COALESCE(ROUND((total_revenue - last_month_revenue) / NULLIF(last_month_revenue, 0) * 100, 2), 0) AS revenue_growth_percentage,
    COALESCE(ROUND((total_sales - last_month_sales) / NULLIF(last_month_sales, 0) * 100, 2), 0) AS sales_growth_percentage
FROM 
    monthly_trends
ORDER BY 
    sales_year, sales_month;
