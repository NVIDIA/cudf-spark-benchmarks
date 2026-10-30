
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        d.d_year,
        COALESCE(cd.cd_gender, 'Unknown') AS gender,
        COALESCE(hd.hd_income_band_sk, -1) AS income_band
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        c.c_customer_id, d.d_year, cd.cd_gender, hd.hd_income_band_sk
),
top_customers AS (
    SELECT 
        c_customer_id,
        total_sales,
        total_orders,
        avg_sales_price,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank,
        income_band
    FROM 
        sales_summary
)
SELECT 
    t.c_customer_id,
    t.total_sales,
    t.total_orders,
    t.avg_sales_price,
    t.sales_rank,
    COALESCE(i.ib_lower_bound, 0) AS income_lower_bound,
    COALESCE(i.ib_upper_bound, 1000000) AS income_upper_bound,
    t.income_band
FROM 
    top_customers t
LEFT JOIN 
    income_band i ON t.income_band = i.ib_income_band_sk
WHERE 
    t.sales_rank <= 10
ORDER BY 
    t.total_sales DESC;
