
WITH sales_summary AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer AS c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        income_band AS ib ON cd.cd_purchase_estimate BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
    WHERE 
        d.d_year = 2023
        AND cd.cd_gender = 'F'
    GROUP BY 
        d.d_year, 
        d.d_month_seq
), month_over_month_growth AS (
    SELECT 
        current.d_month_seq,
        current.total_quantity_sold,
        current.total_sales,
        LAG(current.total_quantity_sold) OVER (ORDER BY current.d_month_seq) AS previous_quantity_sold,
        LAG(current.total_sales) OVER (ORDER BY current.d_month_seq) AS previous_sales,
        ((current.total_quantity_sold - LAG(current.total_quantity_sold) OVER (ORDER BY current.d_month_seq)) / NULLIF(LAG(current.total_quantity_sold) OVER (ORDER BY current.d_month_seq), 0)) * 100 AS quantity_growth,
        ((current.total_sales - LAG(current.total_sales) OVER (ORDER BY current.d_month_seq)) / NULLIF(LAG(current.total_sales) OVER (ORDER BY current.d_month_seq), 0)) * 100 AS sales_growth
    FROM 
        sales_summary AS current
)
SELECT 
    m.d_month_seq,
    m.total_quantity_sold,
    m.total_sales,
    COALESCE(m.quantity_growth, 0) AS quantity_growth,
    COALESCE(m.sales_growth, 0) AS sales_growth
FROM 
    month_over_month_growth AS m
ORDER BY 
    m.d_month_seq;
