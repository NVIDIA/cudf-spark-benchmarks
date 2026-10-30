
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_quantity) AS avg_quantity_per_order,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 
        AND d.d_moy BETWEEN 1 AND 6
    GROUP BY 
        ws.ws_sold_date_sk, cd.cd_gender, cd.cd_marital_status, ib.ib_lower_bound, ib.ib_upper_bound
),
ranked_sales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_data
)
SELECT 
    DATE_TRUNC('month', d.d_date) AS sales_month,
    gd.cd_gender,
    SUM(rs.total_sales) AS monthly_sales,
    COUNT(DISTINCT rs.total_orders) AS unique_orders,
    SUM(rs.avg_quantity_per_order) AS total_avg_quantity
FROM 
    ranked_sales rs
JOIN 
    date_dim d ON rs.ws_sold_date_sk = d.d_date_sk
JOIN 
    customer_demographics gd ON rs.cd_gender = gd.cd_gender
WHERE 
    rs.sales_rank <= 5
GROUP BY 
    sales_month, gd.cd_gender
ORDER BY 
    sales_month, monthly_sales DESC;
